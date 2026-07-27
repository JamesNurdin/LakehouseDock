"""
query_generator_v3 -- plan-diversity-aware QueryDock generator (v2 + pair B/A).

Drop-in replacement for ``query_generator_v2``. The public API is identical --
it exports every name ``Lakehouse`` imports::

    load_schema, make_openai_client, warm_up_model,
    generate_query, generate_query_batch, write_workload_directory,
    fetch_table_columns, fetch_schema_table_columns

so the only change required in ``trino_stack/lakehouse.py`` is swapping::

    from workload_generation.query_generator_v2 import ( ... )
    # ->
    from workload_generation.query_generator_v3 import ( ... )

Why v3
------
v2.1 lifted every *schema-diversity* metric (column coverage, table/edge usage
entropy, unique table-set ratio) but *regressed on plan-space diversity*:
plan-graph Vendi 27.2 -> 22.7, operator-type entropy 0.73 -> 0.66, operator
n-gram entropy 0.77 -> 0.63, and min nearest-neighbour plan distance 0.10 -> 0.0
(i.e. it produced a literal duplicate physical plan). Diagnosis:

  * ~44% of queries used one family ("core_analytical": join-all + group +
    aggregate). Different *tables* (schema coverage stays high) but the *same
    plan template* -> the operator distribution concentrates, so entropy/Vendi
    fall even though the raw count of distinct operators rises.
  * novelty control lived in SQL / static-skeleton space -- a *proxy* for the
    plan graph. Two queries with different SQL skeletons and different table
    sets can still compile to the same physical plan, which is exactly how the
    duplicate plan slipped through.

Both causes are orthogonal to the *selection* layer (the coverage-weighted
table walk, edge-aware walk and column-coverage value aid). v3 therefore
re-uses that layer verbatim and changes only query *structure* and *novelty*:

  B (cheap, lifts intrinsic plan diversity)
    B-1  Rebalanced family weights: "core_analytical" 0.44 -> 0.24, redistributed
         to the families that emit structurally distinct operators (windows,
         nested aggregation, set operations, multi-role joins, string/regex), so
         no single plan template dominates ~half the workload.
    B-2  A per-query ``plan_shape`` axis (star / chain / pre-aggregate / semi-join)
         that changes the *physical plan* -- join topology, aggregation
         placement, semi-join vs inner join -- on the *same* selected tables.
         This decouples plan-space spread from table selection.

  A (guarantees no plan duplicates, flattens the head)
    A-1  Each candidate is EXPLAINed during batch generation; a plan-graph
         signature (operator multiset + operator-edge bigrams, from the same
         DAG the diversity metrics use) is fed to the novelty tracker.
    A-2  Exact plan-graph duplicates are rejected (fixes min-NN 0.0), and an
         over-represented *plan family* (coarse operator multiset) is capped --
         the plan-space analogue of the existing SQL ``skeleton_cap``. This is
         "diversify exactly what you measure".

Everything else -- validity guardrails, the coverage-aware selection layer, the
predicate value aid, temperature jitter, the SQL/skeleton novelty checks -- is
inherited unchanged from v2, so v2.1's schema-diversity gains are preserved.

Cost note: A adds one Trino ``EXPLAIN (FORMAT JSON)`` per generated candidate
(it doubles as validation) and rejects more aggressively, so v3 is slower per
accepted query than v2.1. B lifts base-rate plan diversity so A has less to
reject; tune ``skeleton_cap`` / ``plan_signature_cap`` / ``max_attempt_factor``
to trade wall-clock against strictness.
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

from loader.parser import build_trino_dag

# The whole v2 machinery is re-used (selection layer stays byte-for-byte v2).
from workload_generation.query_generator_v2 import (
    # --- drop-in API names re-exported unchanged ---
    load_schema,
    make_openai_client,
    warm_up_model,
    fetch_table_columns,
    fetch_schema_table_columns,
    # --- helpers v3 composes with (selection + prompt + novelty base) ---
    generate_sql,
    build_schema_context,
    sample_tables_v2,
    build_value_aid,
    build_table_ddl_context,
    fetch_table_columns_cached,
    get_relevant_relationships,
    DiversityTracker,
    _edge_key,
    _dedup_key,
    _skeleton_key,
    _bare_column_name,
    # --- module constants / shared state reused as-is ---
    INSTRUCTIONS_TEMPLATE,
    PROMPT_TEMPLATE,
    ADDON_SPECS,
    ensure_dir,
    WORKLOAD_ROOT,
    MODEL_NAME,
    _VALUE_CACHE,
    _VALUE_CACHE_LOCK,
)
import workload_generation.query_generator_v2 as _v2

__all__ = [
    "load_schema",
    "make_openai_client",
    "warm_up_model",
    "generate_query",
    "generate_query_batch",
    "write_workload_directory",
    "fetch_table_columns",
    "fetch_schema_table_columns",
    "DiversityTrackerV3",
    "PROMPT_VARIANTS",
    "PLAN_SHAPES",
    "ADDON_SPECS",
]

GENERATOR_VERSION = "query_generator_v3"


# ------------------------------------------------------------
# B-1: rebalanced family weights (break the core_analytical monoculture)
# ------------------------------------------------------------
# Task strings are inherited verbatim from v2 so the two stay in sync; only the
# sampling weights change. core_analytical drops from 0.44 to 0.24 and the mass
# is redistributed to families that emit structurally distinct operators.
_V3_FAMILY_WEIGHTS = {
    "simple":             0.13,
    "core_analytical":    0.24,
    "windows_ranking":    0.14,
    "nested_aggregation": 0.14,
    "set_operations":     0.11,
    "multi_role_joins":   0.12,
    "string_regex":       0.12,
}

PROMPT_VARIANTS: list[dict] = []
for _v in _v2.PROMPT_VARIANTS:
    _v = copy.deepcopy(_v)
    _v["weight"] = _V3_FAMILY_WEIGHTS.get(_v["name"], _v["weight"])
    PROMPT_VARIANTS.append(_v)

if abs(sum(v["weight"] for v in PROMPT_VARIANTS) - 1.0) > 1e-6:
    raise ValueError("V3 family weights must sum to 1.0")


# ------------------------------------------------------------
# B-2: per-query plan-shape axis (varies the physical plan, same tables)
# ------------------------------------------------------------
# Applied only to multi-table ("join_all") families -- for "simple",
# "set_operations" and "string_regex" the shape is already pinned by the family
# task. Each line changes the operator graph (join order / topology,
# aggregation placement, or an EXISTS semi-join) without touching which tables
# or columns are selected, so schema coverage is unaffected.
PLAN_SHAPES: list[dict] = [
    {"name": "default", "weight": 0.40, "line": None},
    {"name": "star", "weight": 0.15,
     "line": ("Join shape: use a star topology -- pick the single largest "
              "(fact) table and join every other selected table directly to "
              "it, rather than chaining joins through intermediate tables.")},
    {"name": "chain", "weight": 0.15,
     "line": ("Join shape: use a chain/path topology -- order the joins so "
              "each table joins to the previously joined table, forming a "
              "left-deep chain rather than a hub-and-spoke star.")},
    {"name": "pre_aggregate", "weight": 0.15,
     "line": ("Join shape: pre-aggregate at least one table inside a CTE "
              "(GROUP BY + an aggregate) BEFORE joining it to the others, so "
              "the aggregation sits below the final join rather than only at "
              "the top of the query.")},
    {"name": "semi_join", "weight": 0.15,
     "line": ("Join shape: bring at least one selected table in through an "
              "EXISTS (or IN) semi-join in the WHERE clause instead of an "
              "inner JOIN, so it filters rather than widens the result.")},
]


def sample_shape_spec(rng: random.Random) -> dict:
    """v2's weighted family + add-on draw, plus a B-2 plan-shape draw."""
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


def build_task_text(spec: dict, *, n_tables: int, rng: random.Random,
                    has_join_rules: bool) -> str:
    """Family task + add-ons (delegated to v2) with the plan-shape line appended."""
    task = _v2.build_task_text(spec, n_tables=n_tables, rng=rng,
                               has_join_rules=has_join_rules)
    plan_shape = spec.get("plan_shape")
    if plan_shape and plan_shape.get("line"):
        task += "\n" + plan_shape["line"]
    return task


# ------------------------------------------------------------
# A: plan-graph signatures + plan-space novelty tracker
# ------------------------------------------------------------

def _plan_signatures(plan_json) -> tuple:
    """
    Build (fine_signature, coarse_family) from a Trino plan.

      * coarse_family  -- sorted operator-name multiset. Identifies a *plan
        family* (e.g. "3 InnerJoin + 1 Aggregate + 4 TableScan"); used for the
        plan cap so no single plan template dominates.
      * fine_signature -- hash of (operator multiset + operator-edge bigrams),
        i.e. structure at operator granularity. Two candidates with the same
        fine signature are the plan duplicates min-NN distance measures.

    Uses the same DAG (``loader.parser.build_trino_dag``) the diversity metrics
    are computed from, so the generator diversifies what the notebook scores.
    """
    dag = build_trino_dag(plan_json)
    nodes = dag.get("nodes", {})
    if not nodes:
        return None, None

    op_counts = Counter(n.get("name", "?") for n in nodes.values())
    coarse_family = tuple(sorted(op_counts.items()))

    bigrams = Counter()
    for src, dst, etype in dag.get("edges", []):
        pn = nodes.get(src, {}).get("name", "?")
        cn = nodes.get(dst, {}).get("name", "?")
        bigrams[(pn, cn, etype)] += 1

    fine = (coarse_family, tuple(sorted(bigrams.items())))
    return hash(fine), coarse_family


def _explain_plan_json(conn_factory, sql: str):
    """Best-effort ``EXPLAIN (FORMAT JSON)``. Returns plan dict, or None if the
    query is invalid / Trino errored (treated as an invalid candidate)."""
    sql = (sql or "").strip().rstrip(";")
    if not sql:
        return None
    conn = conn_factory()
    try:
        cur = conn.cursor()
        try:
            cur.execute(f"EXPLAIN (FORMAT JSON) {sql}")
            rows = cur.fetchall()
            if not rows or not rows[0]:
                return None
            raw = rows[0][0]
            return json.loads(raw) if isinstance(raw, str) else raw
        finally:
            cur.close()
    except Exception:
        return None
    finally:
        try:
            conn.close()
        except Exception:
            pass


class DiversityTrackerV3(DiversityTracker):
    """
    v2's tracker (table / edge / column usage + SQL / skeleton novelty) plus two
    plan-space mechanisms (A):

      * ``seen_plan``    -- exact plan-graph fine-signatures -> reject plan
        duplicates outright (min-NN distance 0.0 can no longer occur).
      * ``plan_families``-- coarse operator-multiset counts, capped at
        ``plan_signature_cap`` -> stop any one plan template over-populating the
        workload, which is what dragged operator/n-gram entropy and Vendi down.

    The selection-layer bookkeeping (``table_usage`` / ``edge_usage`` /
    ``column_usage``) is inherited unchanged, so coverage behaviour is identical
    to v2.
    """

    def __init__(self):
        super().__init__()
        self.seen_plan: set = set()
        self.plan_families: Counter = Counter()

    def try_accept(
        self,
        *,
        sql_key: str,
        skeleton,
        tables: list[str],
        skeleton_cap: int,
        edges: list[tuple[str, str]] = (),
        columns: list[str] = (),
        plan_sig=None,
        plan_family=None,
        plan_signature_cap: int | None = None,
        enforce_caps: bool = True,
    ) -> str:
        """
        Atomically test-and-record a candidate. Returns one of:
        "accepted", "duplicate", "plan_duplicate", "plan_capped",
        "near_duplicate", "skeleton_capped".
        """
        fine_key = (skeleton, tuple(sorted(tables)))
        with self.lock:
            if sql_key in self.seen_sql:
                return "duplicate"
            if enforce_caps:
                # Plan-space checks first: they gate exactly what the metrics
                # measure. A candidate that is novel in SQL space but collides
                # in plan space is still a redundancy we want to drop.
                if plan_sig is not None and plan_sig in self.seen_plan:
                    return "plan_duplicate"
                if (
                    plan_signature_cap is not None
                    and plan_family is not None
                    and self.plan_families[plan_family] >= plan_signature_cap
                ):
                    return "plan_capped"
                if fine_key in self.seen_fine:
                    return "near_duplicate"
                if self.skeletons[skeleton] >= skeleton_cap:
                    return "skeleton_capped"

            self.seen_sql.add(sql_key)
            self.seen_fine.add(fine_key)
            self.skeletons[skeleton] += 1
            if plan_sig is not None:
                self.seen_plan.add(plan_sig)
            if plan_family is not None:
                self.plan_families[plan_family] += 1
            self.table_usage.update(tables)
            self.edge_usage.update(edges)
            self.column_usage.update(columns)
            return "accepted"

    def reset(self):
        # Fully overridden (not super().reset()) because threading.Lock is not
        # reentrant -- re-acquiring it inside super() would deadlock.
        with self.lock:
            self.table_usage.clear()
            self.edge_usage.clear()
            self.column_usage.clear()
            self.seen_sql.clear()
            self.skeletons.clear()
            self.seen_fine.clear()
            self.seen_plan.clear()
            self.plan_families.clear()


_DEFAULT_TRACKER_V3 = DiversityTrackerV3()


# ------------------------------------------------------------
# Single-query pipeline (v2's, with the v3 shape spec + plan_shape metadata)
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
    # v3 optional knobs (defaults preserve the drop-in API)
    tracker: DiversityTracker | None = None,
    connected_fraction: float = 0.5,
    value_cache: dict | None = None,
    value_cache_lock=None,
    variant: dict | None = None,
) -> dict:
    """Full single-query pipeline. Identical to v2 except it draws a v3 shape
    spec (rebalanced families + plan_shape) and records the plan_shape used.

    The table / column selection and value aid are the *unchanged* v2 functions,
    so schema-diversity behaviour is preserved exactly."""
    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()
    if tracker is None:
        tracker = _DEFAULT_TRACKER_V3
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
        # v3 metadata
        "plan_shape": plan_shape["name"] if plan_shape else "none",
    }


# ------------------------------------------------------------
# Batch generation with plan-space novelty control (A)
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
    # v3 optional knobs (defaults preserve the drop-in API)
    tracker: DiversityTracker | None = None,
    connected_fraction: float = 0.5,
    skeleton_cap: int = 12,
    plan_signature_cap: int = 8,
    max_attempt_factor: float = 4.0,
) -> list[dict]:
    """
    Batch generation with plan-space novelty control (A) layered on v2's
    SQL/skeleton control.

    Each candidate is EXPLAINed once (``EXPLAIN (FORMAT JSON)``) during
    generation; that call both validates the SQL and yields the plan-graph
    signature. Acceptance rejects, in order: exact SQL duplicates, exact plan
    duplicates, over-represented plan families (``plan_signature_cap``),
    (skeleton, table-set) near-duplicates, and over-represented SQL skeletons
    (``skeleton_cap``). If the attempt budget (``num_queries *
    max_attempt_factor``) is exhausted, still-unique candidates held in overflow
    are used as filler so the caller always receives ``num_queries`` queries --
    diversity degrades gracefully instead of the run stalling.

    The default tracker is module-level, so the repeated batch calls in
    ``Lakehouse.generate_workload``'s validation loop share coverage and novelty
    state across the whole workload -- same as v2.
    """
    rng = random.Random(random_seed)

    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()
    if tracker is None:
        tracker = _DEFAULT_TRACKER_V3

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
    overflow: list[dict] = []  # valid + textually unique, but structurally redundant
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
                    # a genuine plan duplicate is never useful filler
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

    # graceful degradation: fill any shortfall from capped-but-unique queries
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
# Workload writer (v2's artefact layout + v3 provenance / plan_shape mix)
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
    """Same artefact layout as v2 (q<i>.sql + generation_report.json). The
    report additionally records each query's plan_shape and the plan-shape mix,
    and documents the v3 plan-space novelty control."""
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
                v["name"]: {"weight": v["weight"], "task": v["task"]}
                for v in PROMPT_VARIANTS
            },
            "addons": {a["name"]: a["p"] for a in ADDON_SPECS},
            "plan_shapes": {p["name"]: p["weight"] for p in PLAN_SHAPES},
            "semantic_fields": ["goal"],
        },
        "diversity_mechanisms": {
            "profile_calibrated_shapes": (
                "weighted family + add-on sampling (v3: core_analytical "
                "rebalanced 0.44->0.24 to break the dominant plan template)"
            ),
            "plan_shape_variation": (
                "per-query star / chain / pre-aggregate / semi-join hint that "
                "changes the physical plan on the same selected tables "
                "(B: decouples plan diversity from table selection)"
            ),
            "mixed_table_sampling": "coverage-weighted connected walk / connectivity-guaranteed uniform subset (E2ETune)",
            "coverage_aware_seeding": "1/(1+usage) table weighting (SQL-Factory Eq. 7, DiGiT)",
            "edge_aware_walk": "1/(1+edge usage) weighting toward under-covered FK edges (DiGiT gap filling)",
            "predicate_value_aid": "sampled live column values, weighted toward unused columns (E2ETune component 4)",
            "temperature_jitter": "per-family delta on base temperature (SQLStorm temp 1.0)",
            "novelty_control": (
                "A: EXPLAIN-derived plan-graph signature dedup + plan-family cap "
                "(operator multiset), layered on the v2 normalised-SQL dedup, "
                "skeleton cap, and (skeleton, table-set) near-duplicate rejection"
            ),
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
