"""
query_generator_v6 -- diversity-max QueryDock generator (v3 + pure-diversity).

Drop-in replacement for ``query_generator_v3``. Same public API::

    load_schema, make_openai_client, warm_up_model,
    generate_query, generate_query_batch, write_workload_directory,
    fetch_table_columns, fetch_schema_table_columns

so ``trino_stack/lakehouse.py`` swaps one import.

Objective (explicit): MAXIMISE DIVERSITY. Fidelity to real TPC-DS is a
*non-goal*. We no longer calibrate to real's 5.5 joins / 13-74-13 complexity;
plans are allowed to run large and skew complex because that is exactly what
raises plan-graph Vendi, unique skeletons/instances/n-grams and NN distance.
Fidelity metrics (MARE, complexity L1) will worsen by design -- that is the
accepted trade, not a regression.

Lineage & lessons: v6 forks **v3** (not v4/v5). v4's H1 thinning and v5's
fidelity-oriented plan shrinking both *lost* Vendi -- v5 proved that matching
real's small plans shrinks plan diversity, and v4 proved acceptance-time
redistribution can't raise the motif-vocabulary ceiling (stuck ~558 trigrams).
So v6 keeps the two things that are genuinely ours and that SQLStorm lacks --
coverage-weighted selection (schema diversity) and plan-graph dedup
(min-NN > 0) -- and spends its effort on the *generation* side, which is the
only lever that raises the vocabulary ceiling.

Diversity levers (relative to v3)
---------------------------------
D-1  Hot generation. A temperature floor (``V6_TEMPERATURE_FLOOR``) forces
     SQLStorm-style high-temperature sampling regardless of the caller's
     ``temperature``, widening the raw output vocabulary.

D-2  Richer constructs, split into two tiers:
       * always on ("safe rich"): boosted window / set-operation add-ons plus
         anti-join and GROUPING SETS/ROLLUP/CUBE add-ons -- constructs that map
         to distinct physical operators Trino will not normalise away.
       * flag-gated ("exotic", OFF by default): recursive CTEs, correlated
         subqueries, LATERAL joins. These add the most vocabulary but also the
         most invalids/cost, so they are enabled only for testing via env
         ``QUERYDOCK_V6_EXOTIC=1``.

D-3  Wide, bimodal plan size. v5's per-family table caps are *removed*: bulk
     families draw the full ``[min_tables, max_tables]`` band, ``simple`` holds
     a 1-2 low mode and ``multi_role_joins`` a big high mode. Run with a large
     ``max_tables`` (>=16). Size variance spreads plans in plan-space (Vendi,
     NN). ``multi_role_joins`` is kept at v3's weight (v5 halved it for
     fidelity -- undone here, we *want* big deep-join plans).

D-4  Expanded plan-shape vocabulary (8: v3's 5 + outer_join, rollup, windowed).

D-5  Stricter anti-repetition: ``plan_signature_cap`` 8 -> 3. This is the one
     selection lever that genuinely raises diversity -- it forces the accepted
     set to cover more *distinct* plan families instead of repeating any one.

Deliberately NOT done: the attempt budget is NOT increased (``max_attempt_factor``
stays at v3's 4.0) -- runtime was v4's fatal flaw, so the strict cap operates
*within* the same budget and the overflow filler covers any shortfall (a tight
cap with a fixed budget means the tail backfills; that is the accepted cost of
bounding wall-clock). Validity guardrails are also kept (relaxing them would
raise the invalid rate and thus attempts/time).

New: attempt tracking. Per-batch attempt/rejection counts accumulate in a
module-level ``_RUN_STATS`` and are drained into ``generation_report.json``
under ``generation_stats`` by ``write_workload_directory`` -- so every run
records how much of the budget it used and why candidates were rejected.
"""

from __future__ import annotations

import copy
import json
import math
import os
import random
import threading

from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path

# v6 forks v3 (which forks v2). All heavy machinery is imported unchanged; only
# sampling knobs, caps, and stats-tracking differ. v4/v5 are NOT imported.
import workload_generation.query_generator_v3 as _v3
from workload_generation.query_generator_v3 import (
    # --- drop-in API names re-exported unchanged ---
    load_schema,
    make_openai_client,
    warm_up_model,
    fetch_table_columns,
    fetch_schema_table_columns,
    # --- machinery v6 composes with ---
    generate_sql,
    build_task_text,
    build_schema_context,
    sample_tables_v2,
    build_value_aid,
    build_table_ddl_context,
    fetch_table_columns_cached,
    get_relevant_relationships,
    DiversityTrackerV3,
    _plan_signatures,
    _explain_plan_json,
    _edge_key,
    _dedup_key,
    _skeleton_key,
    _bare_column_name,
    # --- shared constants / state reused as-is ---
    ADDON_SPECS,
    INSTRUCTIONS_TEMPLATE,
    PROMPT_TEMPLATE,
    ensure_dir,
    WORKLOAD_ROOT,
    MODEL_NAME,
    _VALUE_CACHE,
    _VALUE_CACHE_LOCK,
)

__all__ = [
    "load_schema",
    "make_openai_client",
    "warm_up_model",
    "generate_query",
    "generate_query_batch",
    "write_workload_directory",
    "fetch_table_columns",
    "fetch_schema_table_columns",
    "PROMPT_VARIANTS",
    "PLAN_SHAPES",
    "V6_ADDON_SPECS",
]

GENERATOR_VERSION = "query_generator_v6"

# D-1: force hot sampling regardless of the caller's temperature (SQLStorm uses
# ~1.0). The per-family temp_delta is still added on top, clamped to [0, 1].
V6_TEMPERATURE_FLOOR = 0.9

# D-2 flag: enable exotic constructs (recursive CTEs, correlated subqueries,
# LATERAL). OFF by default -- they add the most vocabulary but also the most
# invalids/cost, so keep them for testing via env QUERYDOCK_V6_EXOTIC=1.
_V6_EXOTIC = os.environ.get("QUERYDOCK_V6_EXOTIC", "0").strip().lower() not in (
    "", "0", "false", "no", "off",
)


# ------------------------------------------------------------
# D-3: breadth family weights, WIDE ranges (no v5 shrink)
# ------------------------------------------------------------
# multi_role_joins kept at v3's weight (big deep-join plans help Vendi); simple
# held for the low mode of a bimodal size distribution. n_tables_range is NOT
# overridden, so bulk families use the full caller [min_tables, max_tables].
_V6_FAMILY_WEIGHTS = {
    "simple":             0.10,
    "core_analytical":    0.20,
    "windows_ranking":    0.16,
    "nested_aggregation": 0.14,
    "set_operations":     0.16,
    "multi_role_joins":   0.12,
    "string_regex":       0.12,
}

PROMPT_VARIANTS: list[dict] = []
for _v in _v3.PROMPT_VARIANTS:
    _v = copy.deepcopy(_v)
    _v["weight"] = _V6_FAMILY_WEIGHTS.get(_v["name"], _v["weight"])
    PROMPT_VARIANTS.append(_v)  # keep v2/v3 n_tables_range (wide + bimodal)

if abs(sum(v["weight"] for v in PROMPT_VARIANTS) - 1.0) > 1e-6:
    raise ValueError("V6 family weights must sum to 1.0")


# ------------------------------------------------------------
# D-2: richer add-ons (safe rich always on; exotic flag-gated)
# ------------------------------------------------------------
# Start from v3's add-ons, boost the two breadth constructs, then append.
_V6_BASE_ADDONS = copy.deepcopy(ADDON_SPECS)
for _a in _V6_BASE_ADDONS:
    if _a["name"] == "window":
        _a["p"] = 0.20   # was 0.10
    elif _a["name"] == "set_op":
        _a["p"] = 0.15   # was 0.05

_V6_RICH_ADDONS = [
    {"name": "anti_join", "p": 0.12, "simple_ok": False,
     "line": "Include an anti-join: filter with NOT EXISTS or NOT IN against a subquery."},
    {"name": "grouping_sets", "p": 0.12, "simple_ok": False,
     "line": "Use GROUP BY GROUPING SETS, ROLLUP, or CUBE to add subtotal rows."},
]

_V6_EXOTIC_ADDONS = [
    {"name": "recursive_cte", "p": 0.10, "simple_ok": False,
     "line": "Structure the query around a WITH RECURSIVE common table expression."},
    {"name": "correlated_subquery", "p": 0.15, "simple_ok": False,
     "line": "Include a correlated subquery that references the outer query in "
             "the WHERE clause or the SELECT list."},
    {"name": "lateral_join", "p": 0.08, "simple_ok": False,
     "line": "Bring one table in through a LATERAL / correlated join "
             "(CROSS JOIN LATERAL) where the join rules allow."},
]

V6_ADDON_SPECS = _V6_BASE_ADDONS + _V6_RICH_ADDONS + (
    _V6_EXOTIC_ADDONS if _V6_EXOTIC else []
)


# ------------------------------------------------------------
# D-4: expanded plan-shape vocabulary (applied to join_all families)
# ------------------------------------------------------------
PLAN_SHAPES: list[dict] = [
    {"name": "default", "weight": 0.24, "line": None},
    {"name": "star", "weight": 0.11,
     "line": ("Join shape: use a star topology -- pick the single largest "
              "(fact) table and join every other selected table directly to it.")},
    {"name": "chain", "weight": 0.11,
     "line": ("Join shape: use a chain/path topology -- each table joins to the "
              "previously joined table, forming a left-deep chain.")},
    {"name": "pre_aggregate", "weight": 0.11,
     "line": ("Join shape: pre-aggregate at least one table inside a CTE "
              "(GROUP BY + aggregate) BEFORE joining it to the others.")},
    {"name": "semi_join", "weight": 0.11,
     "line": ("Join shape: bring at least one table in through an EXISTS (or IN) "
              "semi-join in the WHERE clause instead of an inner JOIN.")},
    {"name": "outer_join", "weight": 0.11,
     "line": ("Join shape: bring at least one table in through a LEFT OUTER JOIN "
              "and handle the NULLs, so the plan carries an outer-join operator.")},
    {"name": "rollup", "weight": 0.11,
     "line": ("Aggregation shape: use GROUP BY ROLLUP, CUBE, or GROUPING SETS "
              "over two or more grouping columns.")},
    {"name": "windowed", "weight": 0.10,
     "line": ("Add a window function over the joined-and-grouped result "
              "(SUM(...) OVER (...), RANK, or a moving aggregate).")},
]

if abs(sum(p["weight"] for p in PLAN_SHAPES) - 1.0) > 1e-6:
    raise ValueError("V6 plan-shape weights must sum to 1.0")


def sample_shape_spec(rng: random.Random) -> dict:
    """Weighted family + add-on draw (over V6_ADDON_SPECS), plus a plan-shape
    draw for join_all families."""
    weights = [v["weight"] for v in PROMPT_VARIANTS]
    family = rng.choices(PROMPT_VARIANTS, weights=weights, k=1)[0]

    addons = []
    for spec in V6_ADDON_SPECS:
        if family["name"] == "simple" and not spec["simple_ok"]:
            continue
        if family["name"] in spec.get("skip_families", ()):
            continue
        if rng.random() < spec["p"]:
            addons.append(spec)

    plan_shape = None
    if family.get("join_all"):
        plan_shape = rng.choices(PLAN_SHAPES, weights=[p["weight"] for p in PLAN_SHAPES], k=1)[0]

    return {"family": family, "addons": addons, "plan_shape": plan_shape}


# ------------------------------------------------------------
# Attempt tracking: module-level accumulator drained into the report
# ------------------------------------------------------------
_RUN_STATS_LOCK = threading.Lock()
_RUN_STATS: dict = {}


def _record_batch_stats(stats: dict) -> None:
    """Accumulate one batch's attempt/rejection counts (generate_workload may
    call the batch several times before writing)."""
    with _RUN_STATS_LOCK:
        for k, v in stats.items():
            _RUN_STATS[k] = _RUN_STATS.get(k, 0) + v
        _RUN_STATS["batches"] = _RUN_STATS.get("batches", 0) + 1


def _drain_run_stats() -> dict:
    """Return the accumulated stats and reset, so the next workload starts fresh."""
    with _RUN_STATS_LOCK:
        s = dict(_RUN_STATS)
        _RUN_STATS.clear()
    if s.get("attempts") and s.get("accepted") is not None:
        s["acceptance_rate"] = round(s["accepted"] / s["attempts"], 4)
        s["budget_used_pct"] = (
            round(100.0 * s["attempts"] / s["max_attempts"], 1)
            if s.get("max_attempts") else None
        )
    return s


_DEFAULT_TRACKER_V6 = DiversityTrackerV3()


# ------------------------------------------------------------
# Single-query pipeline (v3's body; v6 shape spec + temperature floor)
# ------------------------------------------------------------

def generate_query(
    *,
    conn_factory,
    schema_json: dict,
    catalog: str,
    trino_schema: str,
    client,
    model_name: str = MODEL_NAME,
    temperature: float = 0.6,
    reasoning: str = "medium",
    min_tables: int = 2,
    max_tables: int = 8,
    random_seed: int | None = None,
    ddl_cache: dict[str, list[dict]] | None = None,
    ddl_cache_lock=None,
    tracker: DiversityTrackerV3 | None = None,
    connected_fraction: float = 0.5,
    value_cache: dict | None = None,
    value_cache_lock=None,
    variant: dict | None = None,
) -> dict:
    """v3's single-query pipeline with the v6 shape spec and the D-1 temperature
    floor. Table/column selection and value aid are the unchanged v2 functions."""
    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()
    if tracker is None:
        tracker = _DEFAULT_TRACKER_V6
    if value_cache is None:
        value_cache = _VALUE_CACHE
    if value_cache_lock is None:
        value_cache_lock = _VALUE_CACHE_LOCK

    rng = random.Random(random_seed)

    if variant is not None:
        spec = {"family": variant, "addons": [], "plan_shape": None}
    else:
        spec = sample_shape_spec(rng)
    family = spec["family"]

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

    selected_tables, sampling_mode = sample_tables_v2(
        schema_json,
        n_tables,
        rng=rng,
        table_usage=usage["tables"],
        edge_usage=usage["edges"],
        connected_fraction=connected_fraction,
    )

    ddl_context = build_table_ddl_context(
        conn_factory=conn_factory,
        catalog=catalog,
        schema=trino_schema,
        tables=selected_tables,
        ddl_cache=ddl_cache,
        ddl_cache_lock=ddl_cache_lock,
    )

    columns_by_table = {
        t: fetch_table_columns_cached(
            conn_factory=conn_factory,
            catalog=catalog,
            schema=trino_schema,
            table=t,
            ddl_cache=ddl_cache,
            ddl_cache_lock=ddl_cache_lock,
        )
        for t in selected_tables
    }

    value_aid = build_value_aid(
        conn_factory=conn_factory,
        catalog=catalog,
        schema=trino_schema,
        tables=selected_tables,
        columns_by_table=columns_by_table,
        rng=rng,
        value_cache=value_cache,
        value_cache_lock=value_cache_lock,
        column_usage=usage["columns"],
    )

    schema_context = build_schema_context(
        schema=schema_json,
        selected_tables=selected_tables,
        ddl_context=ddl_context,
        value_aid=value_aid,
    )

    has_join_rules = bool(get_relevant_relationships(schema_json, selected_tables))
    task = build_task_text(
        spec,
        n_tables=len(selected_tables),
        rng=rng,
        has_join_rules=has_join_rules,
    )

    # D-1: floor the base temperature hot, then add the family delta.
    base_temp = max(temperature, V6_TEMPERATURE_FLOOR)
    query_temperature = min(1.0, max(0.0, base_temp + family["temp_delta"]))

    sql_result = generate_sql(
        client=client,
        schema_context=schema_context,
        task=task,
        model_name=model_name,
        temperature=query_temperature,
        reasoning=reasoning,
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
        "prompt_template": PROMPT_TEMPLATE,
        "instructions_template": INSTRUCTIONS_TEMPLATE,
        "model_name": model_name,
        "temperature": query_temperature,
        "catalog": catalog,
        "schema": trino_schema,
        "prompt_variant": family["name"],
        "shape_addons": [a["name"] for a in spec["addons"]],
        "sampling_mode": sampling_mode,
        "plan_shape": plan_shape["name"] if plan_shape else "none",
    }


# ------------------------------------------------------------
# Batch generation -- v3's plan-space novelty control (A), plan cap 3,
# UNCHANGED attempt budget, plus attempt-stats recording.
# ------------------------------------------------------------

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
    tracker: DiversityTrackerV3 | None = None,
    connected_fraction: float = 0.5,
    skeleton_cap: int = 12,
    plan_signature_cap: int = 3,     # D-5: stricter than v3's 8
    max_attempt_factor: float = 4.0,  # UNCHANGED from v3 (runtime bound)
) -> list[dict]:
    """v3's plan-space novelty control with a stricter plan-family cap (3) and
    the same attempt budget. Per-batch attempt/rejection counts are recorded to
    the module-level ``_RUN_STATS`` for the report."""
    rng = random.Random(random_seed)

    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()
    if tracker is None:
        tracker = _DEFAULT_TRACKER_V6

    thread_local = threading.local()

    def get_client():
        if not hasattr(thread_local, "client"):
            thread_local.client = client_factory()
        return thread_local.client

    def worker(seed: int) -> dict:
        q = generate_query(
            conn_factory=conn_factory,
            schema_json=schema_json,
            catalog=catalog,
            trino_schema=trino_schema,
            client=get_client(),
            model_name=model_name,
            temperature=temperature,
            reasoning=reasoning,
            min_tables=min_tables,
            max_tables=max_tables,
            random_seed=seed,
            ddl_cache=ddl_cache,
            ddl_cache_lock=ddl_cache_lock,
            tracker=tracker,
            connected_fraction=connected_fraction,
        )
        if q.get("sql"):
            plan_json = _explain_plan_json(conn_factory, q["sql"])
            if plan_json is None:
                q["plan_valid"] = False
            else:
                sig, family = _plan_signatures(plan_json)
                q["plan_valid"] = sig is not None
                q["plan_sig"] = sig
                q["plan_family"] = family
        else:
            q["plan_valid"] = False
        return q

    def accept_args(q: dict) -> dict:
        sql = q["sql"]
        tables = q.get("selected_tables", [])
        edges = [
            _edge_key(rel[0], rel[2])
            for rel in get_relevant_relationships(schema_json, tables)
        ]
        columns = sorted({
            _bare_column_name(c)
            for c in (q.get("columns_used") or [])
            if isinstance(c, str) and c.strip()
        })
        return {
            "sql_key": _dedup_key(sql),
            "skeleton": _skeleton_key(sql),
            "tables": tables,
            "edges": edges,
            "columns": columns,
        }

    accepted: list[dict] = []
    overflow: list[dict] = []
    attempts = 0
    max_attempts = max(num_queries, math.ceil(num_queries * max_attempt_factor))
    rejected_invalid = 0
    rejected_duplicate = 0
    rejected_plan_dup = 0
    rejected_plan_cap = 0
    rejected_skeleton = 0
    rejected_near_dup = 0

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
                else:  # "duplicate"
                    rejected_duplicate += 1

    # graceful degradation within the SAME budget: fill any shortfall from
    # capped-but-unique queries (plan duplicates are never filler, so min-NN>0
    # is preserved even when the strict cap can't be met inside the budget).
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

    _record_batch_stats({
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


# ------------------------------------------------------------
# Workload writer (v3 layout; tagged v6, records generation_stats)
# ------------------------------------------------------------

def write_workload_directory(
    *,
    workload_name: str,
    queries: list[dict],
    schema_json: dict,
    catalog: str,
    trino_schema: str,
    model_name: str,
    base_url: str,
    temperature: float,
    min_tables: int,
    max_tables: int,
    random_seed: int | None,
    workload_root: str | Path = WORKLOAD_ROOT,
    started_at: datetime | None = None,
    extra_report_fields: dict | None = None,
) -> dict:
    """Same artefact layout as v3, tagged v6, with an added ``generation_stats``
    section (attempts / budget / rejections drained from _RUN_STATS)."""
    if started_at is None:
        started_at = datetime.now(timezone.utc)

    workload_root = Path(workload_root)
    workload_dir = ensure_dir(workload_root / workload_name)

    prompt_examples = []

    for i, query_meta in enumerate(queries, start=1):
        query_name = f"q{i}"
        sql_path = workload_dir / f"{query_name}.sql"
        sql_path.write_text(query_meta["sql"].strip() + "\n", encoding="utf-8")

        query_meta["query_name"] = query_name
        query_meta["file"] = str(sql_path)

        if i <= 3:
            prompt_examples.append({
                "query_name": query_name,
                "selected_tables": query_meta["selected_tables"],
                "schema_context": query_meta["schema_context"],
                "goal": query_meta["goal"],
            })

    ended_at = datetime.now(timezone.utc)

    variant_mix = Counter(q.get("prompt_variant", "unknown") for q in queries)
    sampling_mix = Counter(q.get("sampling_mode", "unknown") for q in queries)
    addon_mix = Counter(a for q in queries for a in q.get("shape_addons", []))
    plan_shape_mix = Counter(q.get("plan_shape", "none") for q in queries)

    generation_stats = _drain_run_stats()

    report = {
        "workload_name": workload_name,
        "workload_dir": str(workload_dir),
        "generator": GENERATOR_VERSION,
        "created_at_utc": started_at.isoformat(),
        "completed_at_utc": ended_at.isoformat(),
        "duration_s": (ended_at - started_at).total_seconds(),
        "num_queries": len(queries),
        "model": {
            "name": model_name,
            "base_url": base_url,
            "temperature": temperature,
        },
        "schema": {
            "catalog": catalog,
            "schema": trino_schema,
            "dataset_name": schema_json.get("name"),
        },
        "selection": {
            "min_tables": min_tables,
            "max_tables": max_tables,
            "random_seed": random_seed,
        },
        "generation_stats": generation_stats,
        "config": {
            "objective": "diversity-max (fidelity is a non-goal)",
            "temperature_floor": V6_TEMPERATURE_FLOOR,
            "exotic_constructs_enabled": _V6_EXOTIC,
            "plan_signature_cap": 3,
            "max_attempt_factor": 4.0,
        },
        "prompting": {
            "instructions_template": INSTRUCTIONS_TEMPLATE,
            "prompt_template": PROMPT_TEMPLATE,
            "families": {
                v["name"]: {"weight": v["weight"],
                            "n_tables_range": v.get("n_tables_range"),
                            "task": v["task"]}
                for v in PROMPT_VARIANTS
            },
            "addons": {a["name"]: a["p"] for a in V6_ADDON_SPECS},
            "plan_shapes": {p["name"]: p["weight"] for p in PLAN_SHAPES},
            "semantic_fields": ["goal"],
        },
        "diversity_mechanisms": {
            "objective": "maximise diversity; NOT calibrated to real TPC-DS",
            "hot_generation": f"D-1: temperature floored at {V6_TEMPERATURE_FLOOR} (SQLStorm-style)",
            "rich_constructs": (
                "D-2: boosted window/set-op add-ons + anti-join + GROUPING SETS "
                f"(exotic recursive/correlated/LATERAL {'ENABLED' if _V6_EXOTIC else 'disabled'})"
            ),
            "wide_bimodal_size": "D-3: full table range (no v5 shrink); simple low mode + multi_role high mode",
            "expanded_plan_shapes": "D-4: 8 plan shapes (v3's 5 + outer_join, rollup, windowed)",
            "strict_plan_cap": "D-5: plan_signature_cap 8 -> 3 (forces more distinct plan families)",
            "plan_novelty_control": (
                "inherited v3 (A): plan-graph dedup (min-NN > 0) + plan-family cap, "
                "on top of v2 SQL/skeleton/near-dup control. Attempt budget unchanged (4x)."
            ),
            "mixed_table_sampling": "coverage-weighted connected walk / connectivity-guaranteed uniform subset (E2ETune)",
            "coverage_aware_seeding": "1/(1+usage) table + edge weighting (SQL-Factory Eq. 7, DiGiT)",
            "predicate_value_aid": "sampled live column values, weighted toward unused columns (E2ETune component 4)",
            "prompt_variant_mix": dict(variant_mix),
            "shape_addon_mix": dict(addon_mix),
            "plan_shape_mix": dict(plan_shape_mix),
            "sampling_mode_mix": dict(sampling_mix),
        },
        "queries": [
            {
                "query_name": q["query_name"],
                "file": q["file"],
                "sql": q["sql"],
                "goal": q["goal"],
                "selected_tables": q["selected_tables"],
                "tables_used": q["tables_used"],
                "columns_used": q["columns_used"],
                "assumptions": q["assumptions"],
                "prompt_variant": q.get("prompt_variant"),
                "shape_addons": q.get("shape_addons", []),
                "plan_shape": q.get("plan_shape"),
                "sampling_mode": q.get("sampling_mode"),
                "temperature": q.get("temperature"),
            }
            for q in queries
        ],
        "prompt_examples": prompt_examples,
    }

    if extra_report_fields:
        report.update(extra_report_fields)

    report_path = workload_dir / "generation_report.json"
    report_path.write_text(json.dumps(report, indent=2, default=str), encoding="utf-8")

    return report
