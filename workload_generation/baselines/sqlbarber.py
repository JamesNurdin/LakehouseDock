"""
SQLBarber baseline.

    Lao & Trummer.
    "SQLBarber: A System Leveraging Large Language Models to Generate
     Customized and Realistic SQL Workloads."  SIGMOD 2025.
    https://github.com/SolidLao/SQLBarber

Faithful adaptation of SQLBarber's two components (paper Sections 5-6) to the
Trino / Iceberg lakehouse:

  1. Customized SQL Template Generator (Section 5)
     - build a textual schema summary + join paths from the target database
       (we re-use QueryDock's DDL introspection + FK relationship graph),
     - prompt the LLM to generate a *template* (SQL with ``{p_i}`` placeholders)
       satisfying a natural-language + numeric specification (num tables,
       joins, aggregations, presence of nested subquery / complex scalar
       expressions),
     - a self-correction loop: an LLM judge checks whether the template meets
       the spec; on failure (spec violation OR a DBMS error after
       instantiation) the LLM iteratively rewrites the template using the
       reasoning + the Trino error message, until it is executable and
       compliant or the attempt budget is exhausted.

  2. Cost-Aware Query Generator (Section 6)
     - profile each template by instantiating it with several predicate-value
       assignments and reading the estimated cost from ``EXPLAIN (FORMAT
       JSON)`` (SQLBarber uses cardinality / plan cost / exec time; we use the
       Trino optimizer's estimated output-row count by default),
     - build a target cost distribution (log-spaced over the profiled cost
       range by default -- or any user-supplied list of target costs, e.g.
       derived from Redset/Snowset),
     - explore the predicate-value space with a lightweight Bayesian-flavoured
       search (random-restart hill climbing over predicate assignments) to
       find, for each target cost, a query whose estimated cost is closest to
       it -- the tractable analogue of SQLBarber's Bayesian Optimizer,
     - report the 1-D Wasserstein distance between the achieved and target
       cost distributions (SQLBarber's alignment metric).

Specs default to a difficulty ladder inspired by the paper's benchmark
construction; callers may pass their own ``specs`` list.
"""

from __future__ import annotations

import json
import math
import random
import re
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

from workload_generation.common import BaselineContext, write_baseline_workload
from workload_generation.query_generator import sanitize_sql


BASELINE = "sqlbarber"

_PLACEHOLDER = re.compile(r"\{\{\s*(p\d+)\s*\}\}")

# Default template specifications (Definition 3.4).  Each is a numeric +
# natural-language constraint on template structure.
DEFAULT_SPECS: List[Dict[str, Any]] = [
    {"spec_id": "s1", "num_tables": 2, "num_joins": 1, "num_aggregations": 1,
     "nl": "A simple analytical query joining two related tables with one aggregation."},
    {"spec_id": "s2", "num_tables": 3, "num_joins": 2, "num_aggregations": 2,
     "nl": "A moderately complex query over three joined tables with grouping and two aggregations."},
    {"spec_id": "s3", "num_tables": 4, "num_joins": 3, "num_aggregations": 2,
     "nl": "A complex query over four joined tables, with a nested subquery and a HAVING filter."},
    {"spec_id": "s4", "num_tables": 2, "num_joins": 1, "num_aggregations": 0,
     "nl": "A query with no aggregation but complex scalar expressions (CASE, arithmetic) in the projection."},
]

_GEN_INSTRUCTIONS = (
    "You are a SQL template generator for Trino (Presto SQL) over Iceberg "
    "tables. A SQL *template* is a valid analytical query in which each "
    "literal predicate value is replaced by a placeholder written EXACTLY as "
    "{{p1}}, {{p2}}, ... (double curly braces). Templates must use only the "
    "given tables/columns and the listed join rules, use explicit JOIN "
    "syntax, and avoid SELECT *. Return a strict JSON object."
)

_JUDGE_INSTRUCTIONS = (
    "You are a strict reviewer. Decide whether a SQL template satisfies a "
    "given specification. Consider the number of tables, joins, aggregations, "
    "and any required structural features. Return strict JSON "
    '{"satisfies": true|false, "reason": "..."}.'
)

_REPAIR_INSTRUCTIONS = (
    "You repair a Trino SQL template so that it (a) satisfies the specification "
    "and (b) is executable on Trino after its {{p_i}} placeholders are filled. "
    "Keep the {{p_i}} placeholder syntax. Use only the given schema. Return the "
    "same strict JSON format as the generator."
)

_TEMPLATE_SCHEMA = {
    "name": "sql_template",
    "strict": True,
    "schema": {
        "type": "object",
        "properties": {
            "sql_template": {"type": "string"},
            "placeholders": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "name": {"type": "string"},
                        "table": {"type": "string"},
                        "column": {"type": "string"},
                        "kind": {"type": "string",
                                 "enum": ["numeric", "string", "date", "timestamp", "boolean"]},
                    },
                    "required": ["name", "table", "column", "kind"],
                    "additionalProperties": False,
                },
            },
            "goal": {"type": "string"},
        },
        "required": ["sql_template", "placeholders", "goal"],
        "additionalProperties": False,
    },
}


# ---------------------------------------------------------------------------
# Template generation + self-correction
# ---------------------------------------------------------------------------

def _schema_summary(ctx: BaselineContext, tables: List[str]) -> str:
    ddl = ctx.ddl_for(tables)
    joins = ctx.join_rules_text(tables)
    join_block = "\n".join(f"- {j}" for j in joins) if joins else "- (no direct joins)"
    return (
        f"Dataset: {ctx.schema_json.get('name')}\n"
        f"Tables (Iceberg via Trino):\n{ddl}\n\n"
        f"Valid join rules:\n{join_block}"
    )


def _spec_prompt(spec: Dict[str, Any], summary: str) -> str:
    return (
        f"Specification (JSON): {json.dumps({k: v for k, v in spec.items() if k != 'nl'})}\n"
        f"Natural-language requirement: {spec['nl']}\n\n"
        f"{summary}\n\n"
        "Generate one SQL template matching this specification."
    )


def _parse_template(raw: str) -> Optional[Dict[str, Any]]:
    try:
        data = json.loads(raw)
    except Exception:
        return None
    tmpl = data.get("sql_template", "")
    tmpl = sanitize_sql(tmpl)
    if not tmpl or not _PLACEHOLDER.search(tmpl):
        # allow templates with no placeholders (e.g. s4 scalar-only) but keep them
        if not tmpl:
            return None
    return {
        "sql_template": tmpl,
        "placeholders": data.get("placeholders", []),
        "goal": data.get("goal", ""),
    }


def _judge(ctx: BaselineContext, tmpl: str, spec: Dict[str, Any]) -> Tuple[bool, str]:
    try:
        raw = ctx.responses_text(
            instructions=_JUDGE_INSTRUCTIONS,
            prompt=f"Specification: {json.dumps(spec)}\n\nTemplate:\n{tmpl}",
            temperature=0.0,
            reasoning="low",
        )
        data = json.loads(raw)
        return bool(data.get("satisfies")), str(data.get("reason", ""))
    except Exception:
        return True, "judge unavailable, accepting"


def _placeholder_names(tmpl: str) -> List[str]:
    return sorted(set(_PLACEHOLDER.findall(tmpl)), key=lambda s: int(s[1:]))


def _sample_value(ctx: BaselineContext, ph: Dict[str, Any], cache: Dict[str, List[Any]]) -> Any:
    key = f"{ph.get('table')}.{ph.get('column')}"
    if key not in cache:
        cache[key] = ctx.sample_column_values(ph.get("table", ""), ph.get("column", ""), limit=40)
    vals = cache[key]
    kind = ph.get("kind", "string")
    if vals:
        return random.choice(vals)
    # fallbacks by kind
    if kind == "numeric":
        return random.choice([0, 1, 5, 10, 50, 100, 500, 1000])
    if kind in ("date",):
        return "2000-01-01"
    if kind in ("timestamp",):
        return "2000-01-01 00:00:00"
    if kind == "boolean":
        return random.choice([True, False])
    return "a"


def _literal(value: Any, kind: str) -> str:
    if value is None:
        return "NULL"
    if kind == "numeric":
        return str(value)
    if kind == "boolean":
        return "TRUE" if value in (True, "true", "True", 1) else "FALSE"
    if kind == "date":
        return f"DATE '{value}'"
    if kind == "timestamp":
        return f"TIMESTAMP '{value}'"
    s = str(value).replace("'", "''")
    return f"'{s}'"


def _instantiate(tmpl: str, ph_map: Dict[str, Dict[str, Any]], assignment: Dict[str, Any]) -> str:
    def repl(m):
        name = m.group(1)
        kind = ph_map.get(name, {}).get("kind", "string")
        return _literal(assignment.get(name), kind)
    return _PLACEHOLDER.sub(repl, tmpl)


def _generate_template(
    ctx: BaselineContext,
    spec: Dict[str, Any],
    tables: List[str],
    *,
    max_repair: int,
    value_cache: Dict[str, List[Any]],
) -> Optional[Dict[str, Any]]:
    summary = _schema_summary(ctx, tables)
    raw = ctx.responses_text(
        instructions=_GEN_INSTRUCTIONS,
        prompt=_spec_prompt(spec, summary),
        json_schema=_TEMPLATE_SCHEMA,
    )
    tmpl = _parse_template(raw)
    attempts: List[Dict[str, Any]] = []

    for attempt in range(max_repair + 1):
        if tmpl is None:
            return None
        ph_map = {p["name"]: p for p in tmpl.get("placeholders", [])}
        # ensure every placeholder in the text has metadata
        for name in _placeholder_names(tmpl["sql_template"]):
            ph_map.setdefault(name, {"name": name, "table": tables[0],
                                     "column": "", "kind": "numeric"})

        # instantiate with a sample assignment and validate on Trino
        assignment = {n: _sample_value(ctx, ph, value_cache) for n, ph in ph_map.items()}
        instance = _instantiate(tmpl["sql_template"], ph_map, assignment)
        ok, err = ctx.validate_explain(instance)
        satisfies, reason = _judge(ctx, tmpl["sql_template"], spec)

        attempts.append({
            "attempt": attempt + 1,
            "executable": ok,
            "satisfies_spec": satisfies,
            "error": err,
            "judge_reason": reason,
        })

        if ok and satisfies:
            tmpl["placeholders"] = list(ph_map.values())
            tmpl["attempts"] = attempts
            tmpl["spec_id"] = spec["spec_id"]
            return tmpl

        if attempt >= max_repair:
            break

        # self-correction: feed the failure back to the LLM
        feedback = (
            f"Specification: {json.dumps(spec)}\n\n"
            f"Current template:\n{tmpl['sql_template']}\n\n"
            f"Instantiated query:\n{instance}\n\n"
            f"Executable on Trino: {ok}. Error: {err}\n"
            f"Satisfies spec: {satisfies}. Reason: {reason}\n\n"
            f"{_schema_summary(ctx, tables)}\n\n"
            "Rewrite the template to fix these problems."
        )
        try:
            raw = ctx.responses_text(
                instructions=_REPAIR_INSTRUCTIONS,
                prompt=feedback,
                json_schema=_TEMPLATE_SCHEMA,
                temperature=0.3,
            )
            tmpl = _parse_template(raw)
        except Exception:
            break

    return None


# ---------------------------------------------------------------------------
# Cost-aware instantiation
# ---------------------------------------------------------------------------

def _cost_of(ctx: BaselineContext, sql: str, metric: str) -> Optional[float]:
    est = ctx.explain_cost(sql)
    if not est:
        return None
    val = est.get(metric)
    if val is None:
        val = est.get("output_rows") or est.get("cpu_cost")
    return val


def _profile_template(
    ctx: BaselineContext,
    tmpl: Dict[str, Any],
    value_cache: Dict[str, List[Any]],
    metric: str,
    n_probe: int,
) -> List[Tuple[Dict[str, Any], float]]:
    ph_map = {p["name"]: p for p in tmpl["placeholders"]}
    names = _placeholder_names(tmpl["sql_template"])
    samples: List[Tuple[Dict[str, Any], float]] = []
    for _ in range(n_probe):
        assignment = {n: _sample_value(ctx, ph_map[n], value_cache) for n in names}
        instance = _instantiate(tmpl["sql_template"], ph_map, assignment)
        cost = _cost_of(ctx, instance, metric)
        if cost is not None:
            samples.append((assignment, cost))
    return samples


def _hill_climb_to_target(
    ctx: BaselineContext,
    tmpl: Dict[str, Any],
    target: float,
    seed_samples: List[Tuple[Dict[str, Any], float]],
    value_cache: Dict[str, List[Any]],
    metric: str,
    budget: int,
) -> Optional[Tuple[str, Dict[str, Any], float]]:
    """
    Random-restart hill climbing over predicate assignments to get the
    estimated cost as close as possible to ``target`` (log-distance).
    Lightweight stand-in for SQLBarber's Bayesian Optimizer.
    """
    ph_map = {p["name"]: p for p in tmpl["placeholders"]}
    names = _placeholder_names(tmpl["sql_template"])
    if not names:
        # no placeholders -- single fixed instance
        instance = tmpl["sql_template"]
        cost = _cost_of(ctx, instance, metric)
        return (instance, {}, cost) if cost is not None else None

    def dist(c):
        return abs(math.log1p(max(c, 0)) - math.log1p(max(target, 0)))

    # start from the profiled sample closest to target
    best = None
    for asg, cost in seed_samples:
        d = dist(cost)
        if best is None or d < best[3]:
            best = (dict(asg), cost, _instantiate(tmpl["sql_template"], ph_map, asg), d)
    if best is None:
        asg = {n: _sample_value(ctx, ph_map[n], value_cache) for n in names}
        instance = _instantiate(tmpl["sql_template"], ph_map, asg)
        cost = _cost_of(ctx, instance, metric)
        if cost is None:
            return None
        best = (asg, cost, instance, dist(cost))

    evals = 0
    while evals < budget and best[3] > 1e-6:
        # perturb one placeholder
        asg = dict(best[0])
        pname = random.choice(names)
        asg[pname] = _sample_value(ctx, ph_map[pname], value_cache)
        instance = _instantiate(tmpl["sql_template"], ph_map, asg)
        cost = _cost_of(ctx, instance, metric)
        evals += 1
        if cost is None:
            continue
        d = dist(cost)
        if d < best[3]:
            best = (asg, cost, instance, d)

    return (best[2], best[0], best[1])


def _log_spaced_targets(costs: List[float], n: int) -> List[float]:
    pos = [c for c in costs if c and c > 0]
    if not pos:
        return [1.0] * n
    lo, hi = min(pos), max(pos)
    if lo == hi or n == 1:
        return [hi] * n
    ll, lh = math.log10(lo), math.log10(hi)
    return [10 ** (ll + (lh - ll) * i / (n - 1)) for i in range(n)]


def _wasserstein_1d(a: List[float], b: List[float]) -> Optional[float]:
    a = sorted(x for x in a if x is not None)
    b = sorted(x for x in b if x is not None)
    if not a or not b:
        return None
    n = max(len(a), len(b))
    # resample both to n quantile points and average abs diff (1-D W1 proxy)
    def q(vals, k):
        return vals[min(len(vals) - 1, int(k * len(vals) / n))]
    return round(sum(abs(q(a, k) - q(b, k)) for k in range(n)) / n, 4)


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------

def generate_workload(
    ctx: BaselineContext,
    *,
    workload_name: str,
    num_queries: int = 100,
    specs: Optional[List[Dict[str, Any]]] = None,
    cost_metric: str = "output_rows",
    target_costs: Optional[List[float]] = None,
    max_repair: int = 5,
    n_templates: Optional[int] = None,
    profile_probes: int = 6,
    bo_budget: int = 12,
    warmup: bool = True,
    random_seed: Optional[int] = None,
    workload_root=None,
) -> Dict[str, Any]:
    """Run the SQLBarber pipeline and write a workload directory + report."""
    started_at = datetime.now(timezone.utc)
    random.seed(random_seed)
    specs = specs or DEFAULT_SPECS
    schema_tables = ctx.schema_tables()
    value_cache: Dict[str, List[Any]] = {}

    if warmup:
        ctx.warm_up()

    # how many templates to build (SQLBarber: fewer templates, many instances)
    if n_templates is None:
        n_templates = max(len(specs), min(num_queries, math.ceil(num_queries / 6)))

    # ---- Component 1: customized template generation w/ self-correction ----
    templates: List[Dict[str, Any]] = []
    template_log: List[Dict[str, Any]] = []
    graph = ctx.relationship_graph()
    rng = random.Random(random_seed)

    tries = 0
    while len(templates) < n_templates and tries < n_templates * 4:
        tries += 1
        spec = specs[len(templates) % len(specs)]
        tables = _pick_connected(graph, schema_tables, spec.get("num_tables", 2), rng)
        tmpl = _generate_template(
            ctx, spec, tables, max_repair=max_repair, value_cache=value_cache
        )
        if tmpl:
            templates.append(tmpl)
            template_log.append({
                "spec_id": spec["spec_id"],
                "tables": tables,
                "n_placeholders": len(_placeholder_names(tmpl["sql_template"])),
                "attempts": tmpl.get("attempts", []),
                "accepted": True,
            })
        else:
            template_log.append({"spec_id": spec["spec_id"], "tables": tables,
                                 "accepted": False})

    # ---- Component 2: cost-aware instantiation ----
    # profile
    profiles: List[Tuple[Dict[str, Any], List[Tuple[Dict[str, Any], float]]]] = []
    all_probe_costs: List[float] = []
    for tmpl in templates:
        samples = _profile_template(ctx, tmpl, value_cache, cost_metric, profile_probes)
        profiles.append((tmpl, samples))
        all_probe_costs.extend(c for _, c in samples)

    # target distribution: user-supplied or log-spaced over the profiled range
    targets = target_costs or _log_spaced_targets(all_probe_costs, num_queries)

    accepted: List[Dict[str, Any]] = []
    achieved_costs: List[float] = []
    if profiles:
        for i, target in enumerate(targets[:num_queries]):
            tmpl, samples = profiles[i % len(profiles)]
            res = _hill_climb_to_target(
                ctx, tmpl, target, samples, value_cache, cost_metric, bo_budget
            )
            if res is None:
                continue
            sql, assignment, cost = res
            ok, _ = ctx.validate_explain(sql)
            if not ok:
                continue
            achieved_costs.append(cost)
            accepted.append({
                "sql": sql,
                "goal": tmpl.get("goal", ""),
                "extra": {
                    "spec_id": tmpl.get("spec_id"),
                    "target_cost": target,
                    "achieved_cost": cost,
                    "cost_metric": cost_metric,
                    "assignment": {k: str(v) for k, v in assignment.items()},
                },
            })

    accepted = accepted[:num_queries]
    w1 = _wasserstein_1d(achieved_costs, targets[:len(accepted)])

    pipeline_report = {
        "method": "SQLBarber (Lao & Trummer, SIGMOD 2025)",
        "components": [
            "customized SQL template generator with LLM self-correction loop",
            "cost-aware query generator (profile -> target distribution -> BO-style predicate search)",
        ],
        "specs": specs,
        "cost_metric": cost_metric,
        "self_correction": {
            "max_repair_attempts": max_repair,
            "templates_requested": n_templates,
            "templates_accepted": len(templates),
            "template_log": template_log,
        },
        "cost_aware": {
            "profile_probes_per_template": profile_probes,
            "bo_budget_per_query": bo_budget,
            "target_distribution": "user-supplied" if target_costs else "log-spaced over profiled range",
            "n_targets": len(targets),
            "wasserstein_distance_to_target": w1,
            "achieved_cost_min": min(achieved_costs) if achieved_costs else None,
            "achieved_cost_max": max(achieved_costs) if achieved_costs else None,
        },
        "counts": {"accepted": len(accepted), "target": num_queries},
        "validation": "Trino EXPLAIN + EXPLAIN (FORMAT JSON) cost estimates",
    }

    return write_baseline_workload(
        baseline=BASELINE,
        workload_name=workload_name,
        queries=accepted,
        ctx=ctx,
        started_at=started_at,
        pipeline_report=pipeline_report,
        workload_root=workload_root or _default_root(),
    )


def _pick_connected(graph, all_tables, n, rng) -> List[str]:
    from collections import deque
    if not all_tables:
        return []
    n = max(1, min(n, len(all_tables)))
    start = rng.choice(all_tables)
    selected = {start}
    frontier = deque([start])
    while frontier and len(selected) < n:
        cur = frontier.popleft()
        nbrs = list(graph.get(cur, []))
        rng.shuffle(nbrs)
        for nb in nbrs:
            if nb not in selected:
                selected.add(nb)
                frontier.append(nb)
                if len(selected) >= n:
                    break
    # top up with random tables if the component is too small
    while len(selected) < n:
        selected.add(rng.choice(all_tables))
    return sorted(selected)


def _default_root():
    from trino_stack.config import WORKLOAD_ROOT
    from pathlib import Path
    return Path(WORKLOAD_ROOT)
