"""
query_generator_v8 -- operator-space-grounded prompt-feedback generator (forks v6).

Why fork v6 (not v7.x)
----------------------
The entire v7 -> v7.1 -> v7.2 feedback arc REGRESSED against v6 on plan-graph
Vendi (TPC-DS, N=1000):

    v6           71.6   (open-loop; the base)
    v6_exotic    72.3   (v6 + exotic add-ons -- the ONLY thing that beat v6)
    v7           54.1   (multiplicative feedback -- collapse)
    v7.1         68.8   (additive floor -- still below v6)
    v7.2         71.3   (n-gram + UCB + exotic + escalation -- back to ~v6, still < v6_exotic)

So reweighting the existing lever set never beat v6. v8 abandons that approach.
It carries NO v7.x machinery (no additive-floor reweighting, no online
attribution, no UCB, no temperature/table escalation) -- only three v7.x
*lessons*, as constraints on new mechanisms:

  L1  multiplicative feedback collapses the distribution -> steer by softmax
      SAMPLING over a deficit, never argmax (protects entropy).
  L2  redistribution cannot raise the vocabulary ceiling -> the ceiling-raiser
      acts at the PROMPT (named operators), not by reweighting add-on fire-rates.
  L3  blind escalation does nothing -> when discovery plateaus, escalate the
      DIRECTED hint pressure at the named deficit, not temperature/plan size.

New machinery (all gated by ``tracker.feedback_enabled``; OFF -> exactly v6, or
v6_exotic with QUERYDOCK_V6_EXOTIC=1)
-------------------------------------
  F-0  Operator-space grounding. The hardcoded operator ceiling and lever->
       operator map (``workload_generation.utils`` over ``resources/*.csv``).
       Diversity is now coverage against a KNOWN reachable operator set.
  F-1  Named-operator deficit hints. Rank under-used reachable operators from
       ``operator_usage``; map each to the SQL construct that yields it (the
       lever table); inject the lever's natural-language ``prompt_hint`` as a
       task line into ``build_task_text``. This puts the deficit where it can
       actually CREATE an operator, not merely change whether a generic add-on
       fires. Selection is softmax over need = 1/(1+usage) (L1); operators are
       sometimes PAIRED in one hint to seed novel plan-graph 3-grams (Vendi).
  F-2  Vendi-aligned reward. The motif unit is the analyzer's own child-path
       operator 3-GRAM COUNTS -- exactly the feature space the Vendi metric
       scores -- replacing v7.2's bigram-set proxy. Drives discovery + the gap
       instrumentation.
  F-4  Directed plateau pressure. When 3-gram discovery halves, raise the number
       of forced hints (``_hint_aggression``), aimed at the still-uncovered tail
       (replaces v7.2's inert temperature/table escalation).
  F-6  Gap instrumentation. Operator coverage, normalised operator entropy, and
       n-gram discovery vs the C_phys ceiling, embedded in the report.

Deferred (documented hooks, not yet wired): F-3 persona/framing diversity;
F-5 using per-lever realised hit-rate to down-weight levers that get optimised
away (the counters are collected now, but not yet fed back into selection).
"""

from __future__ import annotations

import math
import random
import threading

from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed

import workload_generation.query_generator_v6 as _v6
from workload_generation.query_generator_v6 import (
    load_schema,
    make_openai_client,
    warm_up_model,
    fetch_table_columns,
    fetch_schema_table_columns,
    DiversityTrackerV3,
)
from workload_generation import utils as _opspace
# Same DAG builder + n-gram counter the diversity metrics use, so v8 rewards
# exactly what the Vendi score measures.
from loader.parser import build_trino_dag
from loader.workload_analysis import operator_ngram_counts

__all__ = [
    "load_schema",
    "make_openai_client",
    "warm_up_model",
    "generate_query",
    "generate_query_batch",
    "write_workload_directory",
    "fetch_table_columns",
    "fetch_schema_table_columns",
    "DiversityTrackerV8",
]

GENERATOR_VERSION = "query_generator_v8"

# ---- tunables (ablation knobs, NOT statistical thresholds) ----
V8_NGRAM_N = 3                 # F-2: match the analyzer's Vendi n-gram order
V8_HINT_FORCE_P = 0.5          # F-1: P(a query gets any deficit hint) at aggression 0
V8_HINT_PAIR_P = 0.35          # F-1b: P(pair two operators in one query) -> novel 3-grams
V8_SOFTMAX_TEMP = 0.5          # F-1: softmax temperature over deficit scores (L1)
V8_CONDITIONAL_WEIGHT = 0.6    # relative weight of reliability=="conditional" levers
V8_ATTACH_SNIPPET = False      # attach lever example_snippet inline (OFF: snippets use
                               # placeholder table names that can confuse schema grounding)
V8_ESC_WINDOW = 100            # F-4: accepted-plan window for the discovery plateau
V8_MAX_AGGRESSION = 3          # F-4: cap on extra forced hints per query


# ============================================================
# F-2: plan-graph n-gram extraction (Vendi-aligned)
# ============================================================

def _plan_ngrams(plan_json) -> Counter:
    """Child-path operator 3-gram COUNTS of a plan -- the exact motif unit the
    plan-graph Vendi score is computed over (count-weighted, not a set)."""
    dag = build_trino_dag(plan_json)
    return operator_ngram_counts(dag, n=V8_NGRAM_N, include_edge_types=("child",))


def _shannon(counts) -> float:
    total = float(sum(counts))
    if total <= 0:
        return 0.0
    h = 0.0
    for c in counts:
        if c > 0:
            p = c / total
            h -= p * math.log(p)
    return h


# ============================================================
# Tracker: v3 tracker + operator/motif state + F-1 hint selection
# ============================================================

class DiversityTrackerV8(DiversityTrackerV3):
    """v3 tracker plus v8 operator-space state:

      * ``operator_usage`` -- document frequency of rendered plan operators;
        drives the F-1 deficit need = 1/(1+usage).
      * ``ngram_usage``    -- count-weighted child-path 3-grams (F-2); drives
        discovery and the Vendi-gap instrumentation.
      * ``hint_fires`` / ``hint_hits`` -- per-lever realised efficacy (F-5 data;
        collected, not yet fed back).
      * ``_hint_aggression`` -- directed plateau pressure (F-4).

    ``feedback_enabled=False`` -> no hints, no state effect on acceptance == v6.
    """

    def __init__(self):
        super().__init__()
        self.operator_usage: Counter = Counter()
        self.ngram_usage: Counter = Counter()
        self.discovery: list[int] = []
        self.plans_seen: int = 0
        self.hint_fires: Counter = Counter()
        self.hint_hits: Counter = Counter()
        self._hint_aggression: int = 0
        self.feedback_enabled: bool = True

        # F-0: candidate levers restricted to reachable structural operators.
        structural = _opspace.structural_operators()   # read-only + Iceberg
        self._lever_index = _opspace.lever_index()
        self._hint_candidates = tuple(
            lv for lv in _opspace.LEVERS if lv.target_operator in structural
        )

    # ---- accept-time bookkeeping (operators, motifs, hint efficacy) ----
    def try_accept(self, **kwargs) -> str:
        levers = kwargs.pop("levers", ()) or ()
        plan_ngrams = kwargs.pop("plan_ngrams", None)
        plan_family = kwargs.get("plan_family")          # kept for super()'s cap
        verdict = super().try_accept(**kwargs)
        if verdict == "accepted":
            with self.lock:
                self.plans_seen += 1

                plan_ops = set()
                if plan_family is not None:
                    for op, _c in plan_family:
                        self.operator_usage[op] += 1
                        plan_ops.add(op)

                grams = plan_ngrams or Counter()
                new = sum(1 for g in grams if self.ngram_usage.get(g, 0) == 0)
                self.discovery.append(new)
                for g, c in grams.items():
                    self.ngram_usage[g] += c

                # F-5 data: did a hint's target operator actually land?
                for L in levers:
                    lv = self._lever_index.get(L)
                    if lv is None:
                        continue
                    self.hint_fires[L] += 1
                    if lv.target_operator in plan_ops:
                        self.hint_hits[L] += 1

                self._maybe_escalate_locked()
        return verdict

    # ---- F-1: named-operator deficit hints ----
    def deficit_hints(self, rng: random.Random, *, family_name: str) -> list[dict]:
        """Choose deficit-driven operator hints for one query. Returns a list of
        ``{"lever_id", "line"}`` to append as synthetic task-line add-ons."""
        if not self.feedback_enabled or not self._hint_candidates:
            return []
        if family_name == "simple":                      # keep the simple family simple
            return []

        with self.lock:
            aggression = self._hint_aggression
            usage = dict(self.operator_usage)

        if aggression == 0 and rng.random() >= V8_HINT_FORCE_P:
            return []                                     # some queries stay hint-free

        # score(L) = need(op) * reliability   (no UCB -- deficit ranking is already
        # directed exploration; L1: sample, don't argmax)
        scored = []
        for lv in self._hint_candidates:
            need = 1.0 / (1.0 + usage.get(lv.target_operator, 0))
            rel = 1.0 if lv.reliability == "guaranteed" else V8_CONDITIONAL_WEIGHT
            scored.append((lv, need * rel))

        n_ops = 1 + aggression
        if rng.random() < V8_HINT_PAIR_P:                 # F-1b: pair -> novel 3-gram
            n_ops += 1

        chosen = self._sample_distinct_operators(scored, n_ops, rng)
        return [{"lever_id": lv.lever_id, "line": self._hint_line(lv)} for lv in chosen]

    @staticmethod
    def _sample_distinct_operators(scored, n_ops, rng) -> list:
        """Softmax-weighted sampling without replacement, one lever per distinct
        target operator (so a paired hint names two *different* operators)."""
        pool = list(scored)
        chosen, used_ops = [], set()
        while pool and len(chosen) < n_ops:
            weights = [math.exp(s / V8_SOFTMAX_TEMP) for _lv, s in pool]
            lv = rng.choices([lv for lv, _s in pool], weights=weights, k=1)[0]
            chosen.append(lv)
            used_ops.add(lv.target_operator)
            pool = [(l, s) for (l, s) in pool if l.target_operator not in used_ops]
        return chosen

    def _hint_line(self, lv) -> str:
        line = lv.prompt_hint
        if V8_ATTACH_SNIPPET and lv.reliability == "conditional":
            line = f"{line} For example, in the style of: {lv.example_snippet}"
        return line

    # ---- F-4: directed plateau pressure (replaces temp/table escalation) ----
    def _maybe_escalate_locked(self) -> None:
        n = self.plans_seen
        if n < 2 * V8_ESC_WINDOW or n % V8_ESC_WINDOW != 0:
            return
        if self._hint_aggression >= V8_MAX_AGGRESSION:
            return
        base = self.discovery[:V8_ESC_WINDOW]
        recent = self.discovery[-V8_ESC_WINDOW:]
        base_rate = sum(base) / len(base)
        recent_rate = sum(recent) / len(recent)
        if base_rate > 0 and recent_rate < 0.5 * base_rate:
            self._hint_aggression += 1

    # ---- F-6: gap instrumentation for the report ----
    def plan_feedback_snapshot(self) -> dict:
        structural = _opspace.structural_operators()
        with self.lock:
            covered = [op for op in structural if self.operator_usage.get(op, 0) > 0]
            marg = [self.operator_usage.get(op, 0) for op in structural]
            denom = math.log(len(structural)) if len(structural) > 1 else 1.0
            hit_rate = {
                L: round(self.hint_hits[L] / f, 3)
                for L, f in self.hint_fires.items() if f
            }
            return {
                "plans_seen": self.plans_seen,
                "hint_aggression": self._hint_aggression,
                "unique_ngrams": len(self.ngram_usage),
                "operator_coverage": round(len(covered) / max(1, len(structural)), 3),
                "operators_covered": len(covered),
                "operators_reachable": len(structural),
                "operators_missing": sorted(set(structural) - set(covered)),
                "operator_entropy_norm": round(_shannon(marg) / denom, 3) if denom else 0.0,
                "discovery_rate_first100": (
                    sum(self.discovery[:100]) / max(1, len(self.discovery[:100]))
                ),
                "discovery_rate_last100": (
                    sum(self.discovery[-100:]) / max(1, len(self.discovery[-100:]))
                ),
                "operator_usage": dict(self.operator_usage),
                "hint_fires": dict(self.hint_fires),
                "hint_hit_rate": hit_rate,
            }

    def reset(self):
        super().reset()
        with self.lock:
            self.operator_usage.clear()
            self.ngram_usage.clear()
            self.discovery.clear()
            self.plans_seen = 0
            self.hint_fires.clear()
            self.hint_hits.clear()
            self._hint_aggression = 0


_DEFAULT_TRACKER_V8 = DiversityTrackerV8()


# ============================================================
# Single-query pipeline (v6 body + F-1 hint injection)
# ============================================================

def generate_query(
    *,
    conn_factory,
    schema_json: dict,
    catalog: str,
    trino_schema: str,
    client,
    model_name: str = _v6.MODEL_NAME,
    temperature: float = 0.6,
    reasoning: str = "medium",
    min_tables: int = 2,
    max_tables: int = 8,
    random_seed: int | None = None,
    ddl_cache: dict[str, list[dict]] | None = None,
    ddl_cache_lock=None,
    tracker: DiversityTrackerV8 | None = None,
    connected_fraction: float = 0.5,
    value_cache: dict | None = None,
    value_cache_lock=None,
    variant: dict | None = None,
) -> dict:
    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()
    if tracker is None:
        tracker = _DEFAULT_TRACKER_V8
    if value_cache is None:
        value_cache = _v6._VALUE_CACHE
    if value_cache_lock is None:
        value_cache_lock = _v6._VALUE_CACHE_LOCK

    rng = random.Random(random_seed)

    # v6's shape draw is UNCHANGED (no reweighting -- lesson L2).
    if variant is not None:
        spec = {"family": variant, "addons": [], "plan_shape": None}
    else:
        spec = _v6.sample_shape_spec(rng)
    family = spec["family"]

    # F-1: inject named-operator deficit hints as synthetic task-line add-ons.
    # They flow through build_task_text unchanged and are tracked as levers.
    hint_ids: list[str] = []
    if variant is None:
        hints = tracker.deficit_hints(rng, family_name=family["name"])
        for h in hints:
            spec["addons"].append({"name": h["lever_id"], "line": h["line"]})
            hint_ids.append(h["lever_id"])

    # Plan size: v6's (no F-4 table escalation -- pressure goes to hints, not size).
    n_range = family.get("n_tables_range")
    if n_range == "high":
        lo = max(min_tables, min(5, max_tables))
        n_tables = rng.randint(lo, max_tables)
    elif n_range is not None:
        lo, hi = n_range
        n_tables = rng.randint(max(1, lo), max(1, hi))
    else:
        n_tables = rng.randint(min_tables, max_tables)

    usage = tracker.usage_snapshot()

    selected_tables, sampling_mode = _v6.sample_tables_v2(
        schema_json, n_tables, rng=rng,
        table_usage=usage["tables"], edge_usage=usage["edges"],
        connected_fraction=connected_fraction,
    )

    ddl_context = _v6.build_table_ddl_context(
        conn_factory=conn_factory, catalog=catalog, schema=trino_schema,
        tables=selected_tables, ddl_cache=ddl_cache, ddl_cache_lock=ddl_cache_lock,
    )

    columns_by_table = {
        t: _v6.fetch_table_columns_cached(
            conn_factory=conn_factory, catalog=catalog, schema=trino_schema,
            table=t, ddl_cache=ddl_cache, ddl_cache_lock=ddl_cache_lock,
        )
        for t in selected_tables
    }

    value_aid = _v6.build_value_aid(
        conn_factory=conn_factory, catalog=catalog, schema=trino_schema,
        tables=selected_tables, columns_by_table=columns_by_table, rng=rng,
        value_cache=value_cache, value_cache_lock=value_cache_lock,
        column_usage=usage["columns"],
    )

    schema_context = _v6.build_schema_context(
        schema=schema_json, selected_tables=selected_tables,
        ddl_context=ddl_context, value_aid=value_aid,
    )

    has_join_rules = bool(_v6.get_relevant_relationships(schema_json, selected_tables))
    task = _v6.build_task_text(
        spec, n_tables=len(selected_tables), rng=rng, has_join_rules=has_join_rules,
    )

    # v6's hot generation (temperature floor); no F-4 temperature escalation.
    base_temp = max(temperature, _v6.V6_TEMPERATURE_FLOOR)
    query_temperature = min(1.0, max(0.0, base_temp + family["temp_delta"]))

    sql_result = _v6.generate_sql(
        client=client, schema_context=schema_context, task=task,
        model_name=model_name, temperature=query_temperature, reasoning=reasoning,
    )

    plan_shape = spec.get("plan_shape")
    return {
        "sql": sql_result["sql"],
        "goal": sql_result["goal"],
        "tables_used": sql_result["tables_used"],
        "columns_used": sql_result["columns_used"],
        "assumptions": sql_result["assumptions"],
        "selected_tables": selected_tables,
        "ddl_context": ddl_context,
        "schema_context": schema_context,
        "prompt_template": _v6.PROMPT_TEMPLATE,
        "instructions_template": _v6.INSTRUCTIONS_TEMPLATE,
        "model_name": model_name,
        "temperature": query_temperature,
        "catalog": catalog,
        "schema": trino_schema,
        "prompt_variant": family["name"],
        "shape_addons": [a["name"] for a in spec["addons"]],
        "deficit_hints": hint_ids,
        "sampling_mode": sampling_mode,
        "plan_shape": plan_shape["name"] if plan_shape else "none",
    }


def _levers_of(q: dict) -> set:
    levers = set(q.get("shape_addons", []))
    ps = q.get("plan_shape")
    if ps and ps != "none":
        levers.add(ps)
    return levers


# ============================================================
# Batch generation (v6 loop + levers + n-grams for attribution)
# ============================================================

def generate_query_batch(
    *,
    conn_factory,
    schema_json: dict,
    num_queries: int,
    catalog: str,
    trino_schema: str,
    client_factory,
    model_name: str,
    temperature: float = 0.6,
    reasoning="medium",
    min_tables: int = 2,
    max_tables: int = 8,
    random_seed: int | None = None,
    ddl_cache: dict[str, list[dict]] | None = None,
    ddl_cache_lock=None,
    generation_workers: int = 4,
    tracker: DiversityTrackerV8 | None = None,
    connected_fraction: float = 0.5,
    skeleton_cap: int = 12,
    plan_signature_cap: int = 3,
    max_attempt_factor: float = 4.0,
) -> list[dict]:
    rng = random.Random(random_seed)

    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()
    if tracker is None:
        tracker = _DEFAULT_TRACKER_V8

    thread_local = threading.local()

    def get_client():
        if not hasattr(thread_local, "client"):
            thread_local.client = client_factory()
        return thread_local.client

    def worker(seed: int) -> dict:
        q = generate_query(
            conn_factory=conn_factory, schema_json=schema_json, catalog=catalog,
            trino_schema=trino_schema, client=get_client(), model_name=model_name,
            temperature=temperature, reasoning=reasoning, min_tables=min_tables,
            max_tables=max_tables, random_seed=seed, ddl_cache=ddl_cache,
            ddl_cache_lock=ddl_cache_lock, tracker=tracker,
            connected_fraction=connected_fraction,
        )
        if q.get("sql"):
            plan_json = _v6._explain_plan_json(conn_factory, q["sql"])
            if plan_json is None:
                q["plan_valid"] = False
            else:
                sig, family = _v6._plan_signatures(plan_json)
                q["plan_valid"] = sig is not None
                q["plan_sig"] = sig
                q["plan_family"] = family
                try:
                    q["plan_ngrams"] = _plan_ngrams(plan_json)
                except Exception:
                    q["plan_ngrams"] = Counter()
        else:
            q["plan_valid"] = False
        return q

    def accept_args(q: dict) -> dict:
        sql = q["sql"]
        tables = q.get("selected_tables", [])
        edges = [
            _v6._edge_key(rel[0], rel[2])
            for rel in _v6.get_relevant_relationships(schema_json, tables)
        ]
        columns = sorted({
            _v6._bare_column_name(c)
            for c in (q.get("columns_used") or [])
            if isinstance(c, str) and c.strip()
        })
        return {
            "sql_key": _v6._dedup_key(sql),
            "skeleton": _v6._skeleton_key(sql),
            "tables": tables,
            "edges": edges,
            "columns": columns,
            "levers": _levers_of(q),
            "plan_ngrams": q.get("plan_ngrams") or Counter(),
        }

    accepted: list[dict] = []
    overflow: list[dict] = []
    attempts = 0
    max_attempts = max(num_queries, math.ceil(num_queries * max_attempt_factor))
    rejected_invalid = rejected_duplicate = rejected_plan_dup = 0
    rejected_plan_cap = rejected_skeleton = rejected_near_dup = 0

    while len(accepted) < num_queries and attempts < max_attempts:
        need = min(num_queries - len(accepted), max_attempts - attempts)
        seeds = [rng.randint(0, 10**9) for _ in range(need)]
        attempts += need

        with ThreadPoolExecutor(max_workers=min(generation_workers, need)) as executor:
            futures = [executor.submit(worker, seed) for seed in seeds]
            for future in as_completed(futures):
                try:
                    q = future.result()
                except Exception as e:
                    print(f"[generation failed] {type(e).__name__}: {e}")
                    continue

                if not q.get("sql", ""):
                    continue
                if not q.get("plan_valid"):
                    rejected_invalid += 1
                    continue

                verdict = tracker.try_accept(
                    **accept_args(q),
                    skeleton_cap=skeleton_cap,
                    plan_sig=q.get("plan_sig"),
                    plan_family=q.get("plan_family"),
                    plan_signature_cap=plan_signature_cap,
                )

                if verdict == "accepted":
                    accepted.append(q)
                elif verdict == "plan_duplicate":
                    rejected_plan_dup += 1
                elif verdict == "plan_capped":
                    rejected_plan_cap += 1
                    overflow.append(q)
                elif verdict == "skeleton_capped":
                    rejected_skeleton += 1
                    overflow.append(q)
                elif verdict == "near_duplicate":
                    rejected_near_dup += 1
                    overflow.append(q)
                else:
                    rejected_duplicate += 1

    while len(accepted) < num_queries and overflow:
        q = overflow.pop(0)
        verdict = tracker.try_accept(
            **accept_args(q),
            skeleton_cap=skeleton_cap,
            plan_sig=q.get("plan_sig"),
            plan_family=q.get("plan_family"),
            plan_signature_cap=plan_signature_cap,
            enforce_caps=False,
        )
        if verdict == "accepted":
            accepted.append(q)

    _v6._record_batch_stats({
        "attempts": attempts,
        "max_attempts": max_attempts,
        "accepted": len(accepted),
        "rejected_invalid": rejected_invalid,
        "rejected_duplicate": rejected_duplicate,
        "rejected_plan_dup": rejected_plan_dup,
        "rejected_plan_cap": rejected_plan_cap,
        "rejected_skeleton": rejected_skeleton,
        "rejected_near_dup": rejected_near_dup,
    })

    if any((rejected_invalid, rejected_duplicate, rejected_plan_dup,
            rejected_plan_cap, rejected_skeleton, rejected_near_dup)):
        print(
            f"[novelty control] rejected {rejected_invalid} invalid, "
            f"{rejected_duplicate} sql-duplicates, "
            f"{rejected_plan_dup} plan-duplicates, "
            f"{rejected_plan_cap} plan-capped, "
            f"{rejected_near_dup} near-duplicates, "
            f"{rejected_skeleton} skeleton-capped "
            f"({attempts}/{max_attempts} attempts for {len(accepted)} queries)"
        )

    return accepted


# ============================================================
# Workload writer -- reuse v6's, retag v8, embed feedback state.
# ============================================================

def write_workload_directory(
    *,
    tracker: DiversityTrackerV8 | None = None,
    extra_report_fields: dict | None = None,
    **kwargs,
):
    extra = dict(extra_report_fields or {})
    extra["generator"] = GENERATOR_VERSION
    fb = {
        "mechanism": "operator-space-grounded prompt feedback (named-operator deficit hints + Vendi-aligned 3-gram reward)",
        "reward_unit": f"child-path operator {V8_NGRAM_N}-grams (count-weighted, analyzer-aligned)",
        "hint_force_p": V8_HINT_FORCE_P,
        "hint_pair_p": V8_HINT_PAIR_P,
        "softmax_temp": V8_SOFTMAX_TEMP,
        "ceiling_source": "workload_generation.resources (operators_ground_truth.csv + lever_operator_map.csv)",
    }
    if tracker is not None:
        fb.update(tracker.plan_feedback_snapshot())
        fb["feedback_enabled"] = tracker.feedback_enabled
    extra.setdefault("plan_feedback", fb)
    return _v6.write_workload_directory(extra_report_fields=extra, **kwargs)
