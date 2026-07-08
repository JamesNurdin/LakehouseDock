"""
Bootstrapping-LCM baseline (a.k.a. DiGiT SDG pipeline).

    Nidd, Miksovic, Gschwind, Fusco, Giovannini, Giurgiu.
    "Bootstrapping Learned Cost Models with Synthetic SQL Queries."
    VLDB 2025 Workshop AIDB.  https://github.com/menidd/QueryGeneration2025

Faithful adaptation of the DiGiT "Steering SDG towards Diversity" pipeline
(paper Section 4) to Trino / Iceberg:

  * Preprocessing   -- extract schema (tables, columns, types) + FK graph
                       (re-uses QueryDock's introspection).
  * Create Subschema -- enumerate *connected* FK subschemas (connectable table
                       subsets), as DiGiT does (187 groupings for TPC-H). We
                       enumerate connected subsets up to a size cap.
  * DataBuilder     -- for each subschema, build a "few-shot" prompt:
                       CREATE TABLE statements + a few *mechanically generated*
                       example SELECTs built algorithmically from the subschema,
                       then ask for a fresh, more complex query that uses all
                       the subschema's tables. Optional group-by / order-by bias
                       prompt constraint. Multiple generations per prompt with
                       temperature variation (0-shot vs 3-shot settings).
  * Validators      -- filter + dedup by syntactic correctness (Trino EXPLAIN)
                       and relevance.
  * Coverage        -- count table/column/operator usage; bias later rounds
                       toward under-covered tables to fill coverage gaps.

The distinctive features vs QueryDock are: enumerated connected subschemas
(not a single random walk), mechanically-generated few-shot seed examples,
clause-bias prompt constraints, and coverage-gap-driven re-biasing.
"""

from __future__ import annotations

import random
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

from query_gen_eval.common import BaselineContext, write_baseline_workload
from query_gen_eval.sql_features import query_features
from trino_stack.query_generator import sanitize_sql, get_relevant_relationships


BASELINE = "bootstrapping_lcm"

_INSTRUCTIONS = (
    "You are a SQL author generating synthetic training queries for a learned "
    "cost model. Write one valid Trino (Presto) SQL query over the given "
    "Iceberg tables. Use explicit JOIN syntax and only the given tables, "
    "columns and join keys. Avoid SELECT *. Output only the SQL query."
)

# DiGiT "Figure 2" base prompt outline.
_BASE_PROMPT = (
    "These tables have been created:\n{ddl}\n\n"
    "Join keys:\n{joins}\n\n"
    "{bias}"
    "Write an interesting and complicated SQL query that uses all of these tables:\n"
    "{table_list}\n"
    "{examples_block}"
)

_CLAUSE_BIAS = {
    "none": "",
    "group_by": "Whenever possible, please use a GROUP BY clause. Use operators for more complex groups.\n",
    "order_by": "Whenever possible, please use an ORDER BY clause to rank the output.\n",
}


# ---------------------------------------------------------------------------
# Create Subschema: enumerate connected FK subschemas
# ---------------------------------------------------------------------------

def _enumerate_connected_subschemas(
    tables: List[str], graph: Dict[str, set], *, min_size: int, max_size: int,
    cap: int, rng: random.Random,
) -> List[Tuple[str, ...]]:
    """
    Enumerate connected subsets of the FK graph with size in [min_size, max_size].
    For small schemas this is exhaustive (like DiGiT's 187 TPC-H groupings);
    for large schemas we cap the count and sample connected subsets via BFS.
    """
    found: set = set()

    # exhaustive connected-subset enumeration by growing frontiers
    def grow(seed: str):
        # BFS expansions from a seed, recording connected subsets
        stack = [frozenset([seed])]
        while stack and len(found) < cap:
            cur = stack.pop()
            if min_size <= len(cur) <= max_size:
                found.add(tuple(sorted(cur)))
            if len(cur) >= max_size:
                continue
            neighbours = set()
            for t in cur:
                neighbours |= graph.get(t, set())
            for nb in neighbours - cur:
                stack.append(cur | {nb})

    seeds = list(tables)
    rng.shuffle(seeds)
    for s in seeds:
        if len(found) >= cap:
            break
        grow(s)

    result = list(found)
    rng.shuffle(result)
    return result[:cap]


# ---------------------------------------------------------------------------
# Mechanical example generation (DiGiT's algorithmic seed queries)
# ---------------------------------------------------------------------------

def _mechanical_example(
    ctx: BaselineContext, tables: Tuple[str, ...], rng: random.Random,
    bias: str,
) -> str:
    """
    Build a simple valid SELECT algorithmically from a subschema: pick columns,
    join along FK edges, optionally add GROUP BY / ORDER BY per the bias.
    These are used only as few-shot *examples* (not emitted into the workload).
    """
    rels = get_relevant_relationships(ctx.schema_json, list(tables))
    # projection columns
    proj = []
    for t in tables:
        cols = ctx.columns_for(t)
        if cols:
            c = rng.choice(cols)["name"]
            proj.append(f"{t}.{c}")
    if not proj:
        proj = ["*"]
    proj = proj[:4]

    base = tables[0]
    lines = [f"SELECT {', '.join(proj)}", f"FROM {base}"]
    joined = {base}
    for (lt, lcols, rt, rcols) in rels:
        if lt in joined and rt not in joined:
            on = " AND ".join(f"{lt}.{a} = {rt}.{b}" for a, b in zip(lcols, rcols))
            lines.append(f"JOIN {rt} ON {on}")
            joined.add(rt)
        elif rt in joined and lt not in joined:
            on = " AND ".join(f"{lt}.{a} = {rt}.{b}" for a, b in zip(lcols, rcols))
            lines.append(f"JOIN {lt} ON {on}")
            joined.add(lt)

    if bias == "group_by" and proj:
        grp = proj[0]
        lines[0] = f"SELECT {grp}, COUNT(*) AS n"
        lines.append(f"GROUP BY {grp}")
    if bias == "order_by" and proj:
        lines.append(f"ORDER BY {proj[0]}")
    lines.append("LIMIT 100")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# DataBuilder: few-shot prompt
# ---------------------------------------------------------------------------

def _build_prompt(
    ctx: BaselineContext, tables: Tuple[str, ...], *, n_shot: int, bias: str,
    rng: random.Random,
) -> str:
    ddl = ctx.ddl_for(list(tables))
    joins = ctx.join_rules_text(list(tables))
    join_block = "\n".join(f"- {j}" for j in joins) if joins else "- (no direct joins)"
    if n_shot > 0:
        examples = [
            _mechanical_example(ctx, tables, rng, bias) for _ in range(n_shot)
        ]
        examples_block = "\nThese are some examples:\n" + "\n\n".join(
            f"-- example {i+1}\n{e}" for i, e in enumerate(examples)
        )
    else:
        examples_block = ""
    return _BASE_PROMPT.format(
        ddl=ddl,
        joins=join_block,
        bias=_CLAUSE_BIAS.get(bias, ""),
        table_list="\n".join(f"- {t}" for t in tables),
        examples_block=examples_block,
    )


def _generate_one(ctx, tables, n_shot, bias, temperature, seed) -> Dict[str, Any]:
    rng = random.Random(seed)
    prompt = _build_prompt(ctx, tables, n_shot=n_shot, bias=bias, rng=rng)
    raw = ctx.responses_text(
        instructions=_INSTRUCTIONS,
        prompt=prompt,
        temperature=temperature,
    )
    return {
        "sql": sanitize_sql(raw),
        "tables": list(tables),
        "n_shot": n_shot,
        "bias": bias,
    }


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------

def generate_workload(
    ctx: BaselineContext,
    *,
    workload_name: str,
    num_queries: int = 100,
    min_subschema: int = 2,
    max_subschema: int = 5,
    subschema_cap: int = 400,
    n_shot: int = 3,                 # DiGiT: 0-shot vs 3-shot settings
    clause_bias: Optional[List[str]] = None,   # ["none","group_by","order_by"]
    temperatures: Optional[List[float]] = None,  # multiple generations per prompt
    generation_workers: int = 8,
    validation_workers: int = 8,
    max_rounds: int = 12,
    warmup: bool = True,
    random_seed: Optional[int] = None,
    workload_root=None,
) -> Dict[str, Any]:
    """Run the DiGiT SDG pipeline and write a workload directory + report."""
    started_at = datetime.now(timezone.utc)
    rng = random.Random(random_seed)
    clause_bias = clause_bias or ["none", "group_by", "order_by"]
    temperatures = temperatures or [0.6, 0.9]

    if warmup:
        ctx.warm_up()

    schema_tables = ctx.schema_tables()
    graph = ctx.relationship_graph()

    # Create Subschema
    subschemas = _enumerate_connected_subschemas(
        schema_tables, graph, min_size=min_subschema, max_size=max_subschema,
        cap=subschema_cap, rng=rng,
    )
    if not subschemas:  # e.g. no FK edges -- fall back to singletons/pairs
        subschemas = [tuple(sorted(rng.sample(schema_tables,
                       k=min(min_subschema, len(schema_tables)))))
                      for _ in range(min(subschema_cap, 50))]

    accepted: List[Dict[str, Any]] = []
    seen: set = set()
    table_coverage: Counter = Counter()
    op_coverage: Counter = Counter()
    rounds = 0
    total_generated = 0
    total_duplicates = 0

    while len(accepted) < num_queries and rounds < max_rounds:
        rounds += 1
        remaining = num_queries - len(accepted)
        batch = max(4, int(remaining * 1.5))

        # Coverage-gap biasing: prefer subschemas touching under-covered tables
        def gap_score(sub):
            return sum(1.0 / (1 + table_coverage[t]) for t in sub)
        ranked = sorted(subschemas, key=gap_score, reverse=True)
        # sample from the top slice with some randomness
        top = ranked[: max(len(ranked) // 2, batch)]
        chosen = [rng.choice(top) for _ in range(batch)]

        jobs = []
        for sub in chosen:
            bias = rng.choice(clause_bias)
            temp = rng.choice(temperatures)
            shot = n_shot if rng.random() > 0.3 else 0  # mix 0-shot / n-shot
            jobs.append((sub, shot, bias, temp, rng.randint(0, 10**9)))

        candidates: List[Dict[str, Any]] = []
        with ThreadPoolExecutor(max_workers=max(1, generation_workers)) as ex:
            futs = [ex.submit(_generate_one, ctx, *j) for j in jobs]
            for fut in as_completed(futs):
                try:
                    candidates.append(fut.result())
                except Exception as e:
                    print(f"[bootstrapping_lcm] generation failed: {type(e).__name__}: {e}")
        total_generated += len(candidates)

        # Validators: dedup + syntactic correctness (EXPLAIN)
        deduped = []
        for c in candidates:
            key = " ".join(c["sql"].lower().split())
            if not key or key in seen:
                total_duplicates += 1
                continue
            seen.add(key)
            deduped.append(c)

        valid, _invalid = ctx.validate_batch(deduped, workers=validation_workers)
        for c in valid:
            feats = query_features(c["sql"])
            for t in feats.get("tables", []) or c["tables"]:
                table_coverage[t] += 1
            if feats.get("num_group_by"):
                op_coverage["group_by"] += 1
            if feats.get("num_order_by"):
                op_coverage["order_by"] += 1
            if feats.get("num_joins"):
                op_coverage["join"] += 1
            if feats.get("num_aggregations"):
                op_coverage["aggregation"] += 1
            accepted.append({
                "sql": c["sql"],
                "goal": "DiGiT synthetic LCM training query",
                "selected_tables": c["tables"],
                "extra": {"n_shot": c["n_shot"], "clause_bias": c["bias"]},
            })

        if not candidates:
            break

    accepted = accepted[:num_queries]

    pipeline_report = {
        "method": "Bootstrapping-LCM / DiGiT (Nidd et al., VLDB AIDB 2025)",
        "steps": [
            "preprocessing (schema + FK graph)",
            "create subschema (enumerate connected FK subschemas)",
            "DataBuilder few-shot prompt with mechanically-generated examples",
            "validators (dedup + Trino EXPLAIN)",
            "coverage-gap-driven re-biasing",
        ],
        "subschemas": {
            "size_range": [min_subschema, max_subschema],
            "enumerated": len(subschemas),
            "cap": subschema_cap,
        },
        "prompting": {
            "n_shot": n_shot,
            "clause_bias_options": clause_bias,
            "temperatures": temperatures,
            "example_source": "mechanically generated from subschema (algorithmic)",
        },
        "coverage": {
            "table_usage": dict(table_coverage),
            "operator_usage": dict(op_coverage),
        },
        "counts": {
            "rounds": rounds,
            "total_generated": total_generated,
            "duplicates_removed": total_duplicates,
            "accepted": len(accepted),
            "target": num_queries,
        },
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


def _default_root():
    from trino_stack.config import WORKLOAD_ROOT
    from pathlib import Path
    return Path(WORKLOAD_ROOT)
