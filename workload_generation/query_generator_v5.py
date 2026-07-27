"""
query_generator_v5 -- breadth-rebalanced QueryDock generator (v3 + A).

Drop-in replacement for ``query_generator_v3``. The public API is identical --
it exports every name ``Lakehouse`` imports::

    load_schema, make_openai_client, warm_up_model,
    generate_query, generate_query_batch, write_workload_directory,
    fetch_table_columns, fetch_schema_table_columns

so the only change in ``trino_stack/lakehouse.py`` is swapping::

    from workload_generation.query_generator_v3 import ( ... )
    # ->
    from workload_generation.query_generator_v5 import ( ... )

Lineage: v5 continues from **v3**, not v4. v4's H1 soft-motif thinning is
deliberately abandoned -- at 1000 queries it raised operator-n-gram evenness by
only +0.018 while dropping Vendi 3.2, unique skeletons 0.13, unique operator
instances 4.3k, and (via the attempt-budget backfill) reintroducing duplicate
plans (min-NN 0.049 -> 0.0). None of v4 is imported here.

Why v5 (the Vendi diagnosis)
----------------------------
v3 trails SQLStorm on plan-graph Vendi (64.6 vs 79.5 at 1000q), but *not*
because it is too simple. v3 is actually **more** complex than SQLStorm (56%
high-complexity vs 41%, mean 8.9 joins vs 6.3) -- it pours all that complexity
into one archetype, the big multi-join aggregation. Vendi counts *effectively
distinct* plans, so 1000 heavy join-aggregate plans read as few clusters, not
many. SQLStorm wins on **breadth**, not depth:

  * 809 distinct operator trigrams vs v3's 558 (motif vocabulary)
  * 7x the set operations (1.73 vs 0.23 / query), 2x the CTEs (3.28 vs 1.45),
    more window functions (1.08 vs 0.42)
  * a wider size spread (4-1058 tokens vs 14-689)

v3's 56%-high skew is also its worst fidelity error (real TPC-DS is 13% high),
so the same correction helps *both* notebook axes at once.

Approach A -- three sampling changes (no new runtime mechanism)
---------------------------------------------------------------
A-1  **Breadth-rebalanced family weights.** Mass moves toward the families
     that emit structurally distinct operators (``set_operations`` 0.11->0.16,
     the single biggest gap to SQLStorm) and away from the pure-high-complexity
     deep-join family (``multi_role_joins`` 0.12->0.06) that homogenises the
     workload into big joins. ``simple`` rises (0.13->0.16) to widen the low
     tail. Higher motif vocabulary + wider size spread => higher Vendi.

A-2  **Per-family table-count ranges.** In v3 every non-"high" family drew
     ``randint(min_tables, max_tables)``; with a large caller ``max_tables``
     (e.g. 16) that pushed most queries past 8 joins, i.e. into "high", which
     is what produced the 56%-high skew. v5 pins an explicit table range per
     family (see ``_V5_N_TABLES_RANGES``) so the bulk of the workload lands at
     2-6 tables (medium complexity, ~real joins/query) while ``simple`` (1-2)
     and ``multi_role_joins`` ("high", up to the caller's ``max_tables``) hold
     the two tails. Bulk families span 3-9 tables (<=8 joins => "medium", never
     tipping into >8 == "high" on join count alone), so the table mean lands
     near real (~5.5) instead of v3's 9.0, while ``simple`` (1-2) and
     ``multi_role_joins`` (up to the caller's ``max_tables``) hold the low/high
     tails. This *decouples* the complexity distribution from the caller's
     ``max_tables`` and widens size variance (Vendi) while pulling the mix back
     toward 13/74/13 (fidelity); ``max_tables`` now sets the
     ``multi_role_joins`` ceiling only.

A-3  **Expanded plan-shape vocabulary.** v3's per-query plan-shape axis (B-2)
     had 5 hints; v5 adds ``outer_join`` (LEFT OUTER -> distinct join operator +
     NULL handling), ``rollup`` (GROUPING SETS / ROLLUP / CUBE -> distinct
     aggregation operators) and ``windowed`` (a window over the joined result),
     and lifts the share of *non-default* shapes from 0.60 to 0.76. Same tables,
     more distinct physical plans => more trigram vocabulary => higher Vendi.

Everything else is v3 verbatim: the coverage-aware selection layer, the value
aid, the SQL/skeleton novelty checks, and -- crucially -- v3's exact plan-graph
dedup + plan-family cap (A) that gives min-NN > 0 (zero duplicate plans). The
batch loop and tracker are v3's; only what gets *sampled* changes.
"""

from __future__ import annotations

import copy
import json
import math
import random
import threading

from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path

# v5 continues from v3 (which continues from v2). Every heavy component --
# selection, value aid, plan signatures, EXPLAIN, the plan-dedup tracker, the
# structured-output LLM call -- is imported from v3 unchanged. Only the sampling
# knobs below differ. v4 is intentionally NOT imported.
import workload_generation.query_generator_v3 as _v3
from workload_generation.query_generator_v3 import (
    # --- drop-in API names re-exported unchanged ---
    load_schema,
    make_openai_client,
    warm_up_model,
    fetch_table_columns,
    fetch_schema_table_columns,
    # --- machinery v5 composes with (all v3/v2, no v4) ---
    generate_sql,
    build_task_text,             # reads spec["plan_shape"], so v5 shapes work
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
]

GENERATOR_VERSION = "query_generator_v5"


# ------------------------------------------------------------
# A-1 + A-2: breadth-rebalanced families with explicit table ranges
# ------------------------------------------------------------
# Weights push mass toward construct-diverse families and away from the
# homogenising deep-join family; ranges pin the complexity distribution so it
# no longer runs away to "high" under a large caller max_tables.
_V5_FAMILY_WEIGHTS = {
    "simple":             0.16,   # up  0.13 -> widen the low tail
    "core_analytical":    0.22,
    "windows_ranking":    0.15,
    "nested_aggregation": 0.13,
    "set_operations":     0.16,   # up  0.11 -> biggest breadth gap vs SQLStorm
    "multi_role_joins":   0.06,   # down 0.12 -> stop homogenising into big joins
    "string_regex":       0.12,
}

# Per-family table-count ranges. "high" == top of the caller's [min,max] band
# (kept for the intentional high-complexity tail); a tuple pins that family's
# range regardless of the caller's max_tables. Bulk families sit at 2-6 so
# join counts land near real (~5.5) instead of tipping into >8 == "high".
_V5_N_TABLES_RANGES = {
    "simple":             (1, 2),
    "core_analytical":    (3, 9),
    "windows_ranking":    (3, 9),
    "nested_aggregation": (3, 9),
    "set_operations":     (2, 8),
    "multi_role_joins":   "high",
    "string_regex":       (2, 8),
}

PROMPT_VARIANTS: list[dict] = []
for _v in _v3.PROMPT_VARIANTS:
    _v = copy.deepcopy(_v)
    _v["weight"] = _V5_FAMILY_WEIGHTS.get(_v["name"], _v["weight"])
    if _v["name"] in _V5_N_TABLES_RANGES:
        _v["n_tables_range"] = _V5_N_TABLES_RANGES[_v["name"]]
    PROMPT_VARIANTS.append(_v)

if abs(sum(v["weight"] for v in PROMPT_VARIANTS) - 1.0) > 1e-6:
    raise ValueError("V5 family weights must sum to 1.0")


# ------------------------------------------------------------
# A-3: expanded plan-shape vocabulary (applied to join_all families)
# ------------------------------------------------------------
# v3's five shapes + three that introduce distinct physical operators. Only
# join_all families draw a shape (for simple / set_operations / string_regex the
# family task already pins the plan), so this diversifies exactly the big
# multi-join archetype that was collapsing Vendi.
PLAN_SHAPES: list[dict] = [
    {"name": "default", "weight": 0.24, "line": None},
    {"name": "star", "weight": 0.11,
     "line": ("Join shape: use a star topology -- pick the single largest "
              "(fact) table and join every other selected table directly to "
              "it, rather than chaining joins through intermediate tables.")},
    {"name": "chain", "weight": 0.11,
     "line": ("Join shape: use a chain/path topology -- order the joins so "
              "each table joins to the previously joined table, forming a "
              "left-deep chain rather than a hub-and-spoke star.")},
    {"name": "pre_aggregate", "weight": 0.11,
     "line": ("Join shape: pre-aggregate at least one table inside a CTE "
              "(GROUP BY + an aggregate) BEFORE joining it to the others, so "
              "the aggregation sits below the final join rather than only at "
              "the top of the query.")},
    {"name": "semi_join", "weight": 0.11,
     "line": ("Join shape: bring at least one selected table in through an "
              "EXISTS (or IN) semi-join in the WHERE clause instead of an "
              "inner JOIN, so it filters rather than widens the result.")},
    # --- v5 additions (A-3) ---
    {"name": "outer_join", "weight": 0.11,
     "line": ("Join shape: bring at least one selected table in through a LEFT "
              "OUTER JOIN (preserving unmatched rows) instead of an inner "
              "join, and handle the resulting NULLs in the projection or a "
              "COALESCE, so the plan carries an outer-join operator.")},
    {"name": "rollup", "weight": 0.11,
     "line": ("Aggregation shape: use GROUP BY ROLLUP, CUBE, or GROUPING SETS "
              "over two or more grouping columns to produce subtotal rows, "
              "rather than a single flat GROUP BY.")},
    {"name": "windowed", "weight": 0.10,
     "line": ("Add a window function over the joined-and-grouped result "
              "(e.g. SUM(...) OVER (PARTITION BY ... ORDER BY ...), RANK, or a "
              "moving aggregate) in addition to the base aggregation, so the "
              "plan carries a window operator.")},
]

if abs(sum(p["weight"] for p in PLAN_SHAPES) - 1.0) > 1e-6:
    raise ValueError("V5 plan-shape weights must sum to 1.0")


# ------------------------------------------------------------
# Shape draw (v3's, reading v5's PROMPT_VARIANTS / PLAN_SHAPES)
# ------------------------------------------------------------

def sample_shape_spec(rng: random.Random) -> dict:
    """Weighted family + add-on draw, plus a plan-shape draw for join_all
    families. Identical to v3's, but resolves this module's rebalanced
    PROMPT_VARIANTS and expanded PLAN_SHAPES."""
    weights = [v["weight"] for v in PROMPT_VARIANTS]
    family = rng.choices(PROMPT_VARIANTS, weights=weights, k=1)[0]

    addons = []
    for spec in ADDON_SPECS:
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
# Single-query pipeline (v3's body; binds to v5's sample_shape_spec + tracker)
# ------------------------------------------------------------

_DEFAULT_TRACKER_V5 = DiversityTrackerV3()


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
    """Full single-query pipeline -- v3's, unchanged except it draws a v5 shape
    spec (rebalanced families + per-family ranges + expanded plan shapes).
    Table/column selection and the value aid are the same v2 functions, so
    schema-diversity behaviour is preserved exactly."""
    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()
    if tracker is None:
        tracker = _DEFAULT_TRACKER_V5
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

    query_temperature = min(1.0, max(0.0, temperature + family["temp_delta"]))

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
# Batch generation -- v3's plan-space novelty control (A), verbatim logic;
# only the worker's call to generate_query resolves to v5's.
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
    plan_signature_cap: int = 8,
    max_attempt_factor: float = 4.0,
) -> list[dict]:
    """Batch generation with v3's plan-space novelty control (A): each
    candidate is EXPLAINed once (validate + plan signature), then acceptance
    rejects SQL duplicates, exact plan duplicates, over-represented plan
    families, (skeleton, table-set) near-duplicates, and over-represented SQL
    skeletons. Overflow backfills any shortfall. No v4/H1 soft thinning."""
    rng = random.Random(random_seed)

    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()
    if tracker is None:
        tracker = _DEFAULT_TRACKER_V5

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

    if any((rejected_invalid, rejected_duplicate, rejected_plan_dup,
            rejected_plan_cap, rejected_skeleton, rejected_near_dup)):
        print(
            f"[novelty control] rejected {rejected_invalid} invalid, "
            f"{rejected_duplicate} sql-duplicates, "
            f"{rejected_plan_dup} plan-duplicates, "
            f"{rejected_plan_cap} plan-capped, "
            f"{rejected_near_dup} near-duplicates, "
            f"{rejected_skeleton} skeleton-capped "
            f"({attempts} attempts for {len(accepted)} queries)"
        )

    return accepted


# ------------------------------------------------------------
# Workload writer (v3 layout; tagged v5, documents approach A)
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
    """Same artefact layout as v3, tagged v5, documenting the approach-A
    breadth rebalance (families, per-family table ranges, expanded shapes)."""
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
        "prompting": {
            "instructions_template": INSTRUCTIONS_TEMPLATE,
            "prompt_template": PROMPT_TEMPLATE,
            "families": {
                v["name"]: {"weight": v["weight"],
                            "n_tables_range": v.get("n_tables_range"),
                            "task": v["task"]}
                for v in PROMPT_VARIANTS
            },
            "addons": {a["name"]: a["p"] for a in ADDON_SPECS},
            "plan_shapes": {p["name"]: p["weight"] for p in PLAN_SHAPES},
            "semantic_fields": ["goal"],
        },
        "diversity_mechanisms": {
            "breadth_rebalanced_families": (
                "A-1: family mass shifted toward construct-diverse families "
                "(set_operations 0.11->0.16) and away from the homogenising "
                "multi_role_joins (0.12->0.06); simple up 0.13->0.16"
            ),
            "per_family_table_ranges": (
                "A-2: explicit per-family table-count ranges pin the complexity "
                "distribution toward 13/74/13 and widen size variance, "
                "decoupled from the caller's max_tables (which now sets the "
                "multi_role_joins ceiling only)"
            ),
            "expanded_plan_shapes": (
                "A-3: plan-shape vocabulary grown to 8 (added outer_join, "
                "rollup, windowed); non-default share 0.60->0.76 -- more "
                "distinct physical plans on the same tables"
            ),
            "plan_novelty_control": (
                "inherited from v3 (A): EXPLAIN-derived plan-graph signature "
                "dedup (min-NN > 0) + plan-family cap, on top of v2 "
                "normalised-SQL dedup, skeleton cap, and near-duplicate "
                "rejection. NO v4/H1 soft motif thinning."
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
