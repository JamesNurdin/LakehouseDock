"""
query_generator_v2 -- diversity-aware QueryDock generator.

Drop-in replacement for ``query_generator`` (v1). The public API is identical
-- it exports every name ``Lakehouse`` imports from v1::

    load_schema, make_openai_client, warm_up_model,
    generate_query, generate_query_batch, write_workload_directory,
    fetch_table_columns, fetch_schema_table_columns

so swapping ``workload_generation.query_generator`` for
``workload_generation.query_generator_v2`` in ``trino_stack/lakehouse.py`` is
the only change required. All v1 helpers that are unchanged are re-used (not
copied) from v1.

Motivation
----------
On ``tpcds_baseline_diversity_comparison_1000.csv`` QueryDock v1 trailed
E2ETune and SQLStorm on exactly the metrics their pipelines explicitly
optimise: column coverage (0.694 vs E2ETune 0.889), table-usage entropy
(0.896 vs 0.991), unique-table-set ratio (0.613 vs 0.877), mean
nearest-neighbour distance (0.186 vs SQLStorm 0.270), unique-skeleton ratio
(0.253 vs 0.553) and Vendi score (52.0 vs 79.5). Each v1 weakness maps to a
missing mechanism that one of the baselines has; v2 adds those mechanisms
while keeping v1's strength (guardrail-driven first-shot validity).

Changes (each tagged ``CHANGE-n`` at the implementation site)
--------------------------------------------------------------
CHANGE-1  Mixed table sampling: with probability ``connected_fraction`` keep
          v1's connected FK walk (guarantees joinable subsets), otherwise draw
          a uniform random subset of tables with no connectivity constraint.
          *Why*: v1's BFS walk over-samples high-degree hub tables (date_dim,
          item, store, ...) in a snowflake schema, which depressed
          table-usage entropy and the unique-table-set ratio. E2ETune samples
          tables uniformly at random per query ("diversity control (1)") and
          scores near-maximal table entropy (0.991) and 877/1000 unique table
          sets.

CHANGE-2  Coverage-aware seeding of the connected walk: the walk's start table
          and its expansion steps are weighted by ``1 / (1 + usage)`` so
          under-used tables are preferred as generation proceeds.
          *Why*: v1's sampling is memoryless -- query 900 knows nothing about
          queries 1-899. SQL-Factory's Table Selection Agent (its Eq. 7)
          weights tables by ``complexity / (1 + coverage)`` and DiGiT
          re-biases later rounds toward under-covered tables; both close
          coverage gaps that pure random sampling leaves open.

CHANGE-3  A prompt-variant suite instead of one fixed instruction: each query
          draws one of several task variants of graded complexity and
          construct focus (windows, set operations, strings, nested
          aggregation, deliberately simple, ...). The single v1 steering line
          "Prefer analytical queries with joins, filters, grouping,
          aggregation, or ordering" is removed from the shared rules -- shape
          steering now lives only in the variant.
          *Why*: one fixed prompt at fixed temperature collapses the model
          onto one canonical SELECT-JOIN-WHERE-GROUP BY shape (v1: 253 unique
          skeletons, NN distance 0.186, subquery mean 0.105, set-op mean
          0.02). SQLStorm's whole generation step is a suite of 7 prompts
          (P1-P7) of graded complexity, and it leads every shape-diversity
          metric (553 skeletons, NN 0.270, 41.3% high-complexity, Vendi 79.5).

CHANGE-4  Predicate Generation Aid: sample real column values from the live
          lakehouse and show a handful of "column: example values" lines in
          the prompt.
          *Why*: with DDL only, the model reuses the same few "obvious"
          predicate columns and invents generic literals -- the main driver of
          v1's column-coverage gap (0.694 vs 0.889). This is E2ETune's prompt
          component 4 and its second diversity lever (random sampled values
          per query); the mechanism is deliberately identical to the one in
          ``baselines/e2etune.py`` so the comparison stays a fair ablation.

CHANGE-5  Per-variant temperature jitter around the caller's ``temperature``
          (complex variants sample hotter, the simple variant cooler).
          *Why*: SQLStorm generates at temperature 1.0 precisely because
          output diversity is the goal; v1 used a single 0.6 for every query.
          Keeping the caller's value as the base preserves the v1 API and
          default behaviour while restoring variance between queries.

CHANGE-6  Novelty control at acceptance time: exact-duplicate rejection on
          normalised SQL text plus a cap on how many accepted queries may
          share one structural skeleton; rejected slots are regenerated within
          a bounded attempt budget.
          *Why*: v1 accepted everything that passed EXPLAIN, so undetected
          near-duplicates depressed nearest-neighbour distance and the Vendi
          score. SQLStorm dedups normalised query text before selection, and
          SQL-Factory's Critical Agent rejects candidates that are too similar
          to the existing pool; both mechanisms directly target the
          repetition v1 could not see. (The skeleton key reuses
          ``sql_features.query_features`` so "similarity" is the same notion
          the evaluation reports.)

What is deliberately kept from v1
---------------------------------
The validity guardrails (don't invent tables/columns/join keys, qualify
ambiguous columns, the ``*_date_sk`` note, CTE projection rules) are retained:
they are what gives QueryDock its 100% EXPLAIN pass rate, and none of them
constrains query *shape*. The date guidance is softened so it no longer
instructs the model to join ``date_dim`` (which reinforced the hub-table bias
CHANGE-1 removes).
"""

from __future__ import annotations

import json
import math
import random
import re
import threading
import time

from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path
from _thread import LockType

from openai import OpenAI

from trino_stack.workload import ensure_dir
from trino_stack.config import WORKLOAD_ROOT, MODEL_NAME

# Unchanged machinery is re-used from v1 (and re-exported for API parity).
from workload_generation.query_generator import (
    load_schema,
    make_openai_client,
    warm_up_model,
    call_with_retry,
    build_relationship_graph,
    relationship_to_text,
    get_relevant_relationships,
    fetch_table_columns,
    fetch_table_columns_cached,
    fetch_schema_table_columns,
    build_table_ddl_context,
    extract_schema_tables,
    sanitize_sql,
    normalise_sql_result,
)
from workload_generation.sql_features import query_features

__all__ = [
    "load_schema",
    "make_openai_client",
    "warm_up_model",
    "generate_query",
    "generate_query_batch",
    "write_workload_directory",
    "fetch_table_columns",
    "fetch_schema_table_columns",
    "DiversityTracker",
    "PROMPT_VARIANTS",
]


# ------------------------------------------------------------
# CHANGE-3: prompt-variant suite (SQLStorm P1-P7 analogue)
# ------------------------------------------------------------
# Each variant: (name, task text, temperature delta applied to the caller's
# temperature -- CHANGE-5). The set spans SQLStorm's graded-complexity idea
# (elaborate -> plain -> simple -> strings) plus SQL-Factory's Generation
# Agent focus (window functions, CASE WHEN, RANK/DENSE_RANK) and a nested
# aggregation shape v1 almost never produced.

PROMPT_VARIANTS: list[dict] = [
    {
        "name": "analytical",
        "task": (
            "Generate one analytical SQL query with joins, filtering, "
            "grouping, aggregation, and/or ordering."
        ),
        "temp_delta": 0.0,
    },
    {
        "name": "complex_constructs",
        "task": (
            "Generate one interesting and elaborate analytical SQL query, "
            "potentially including constructs such as outer joins, "
            "(correlated) subqueries, CTEs, window functions, complicated "
            "predicates/expressions/calculations, and NULL logic."
        ),
        "temp_delta": +0.3,
    },
    {
        "name": "simple",
        "task": (
            "Generate one simple SQL query: a scan with selective filter "
            "predicates and a small projection, using at most one join and "
            "no more than one aggregate."
        ),
        "temp_delta": -0.2,
    },
    {
        "name": "set_operations",
        "task": (
            "Generate one analytical SQL query built around a set operation "
            "(UNION, UNION ALL, INTERSECT, or EXCEPT) combining two or more "
            "sub-selects."
        ),
        "temp_delta": +0.2,
    },
    {
        "name": "windows_ranking",
        "task": (
            "Generate one analytical SQL query that uses window functions "
            "and conditional logic, such as RANK, DENSE_RANK, ROW_NUMBER, "
            "moving aggregates over a window frame, and CASE WHEN "
            "expressions."
        ),
        "temp_delta": +0.2,
    },
    {
        "name": "nested_aggregation",
        "task": (
            "Generate one analytical SQL query that aggregates in a CTE or "
            "subquery and then aggregates or filters over that result again "
            "(e.g. an average of per-group sums, or HAVING against a derived "
            "aggregate)."
        ),
        "temp_delta": +0.1,
    },
    {
        "name": "string_processing",
        "task": (
            "Generate one interesting analytical SQL query that exercises "
            "string processing: string functions, pattern matching with "
            "LIKE, concatenation, or substring manipulation in predicates or "
            "projections."
        ),
        "temp_delta": +0.2,
    },
]

PROMPT_TEMPLATE = """
Schema context:
{schema_context}

Task:
{task}
""".strip()

# v1's validity guardrails are retained (they drive the 100% EXPLAIN pass
# rate and do not constrain query shape); the one *shape-steering* line
# ("Prefer analytical queries with joins, filters, grouping, aggregation, or
# ordering") is removed -- shape now comes from the variant (CHANGE-3). The
# date_dim guidance no longer tells the model to join date_dim, which
# reinforced the hub bias CHANGE-1 removes.
INSTRUCTIONS_TEMPLATE = """
You are an expert SQL generation system.

Generate one valid Trino SQL query using only the provided schema context.
Do not invent tables, columns, or join keys.
Use explicit JOIN syntax.
Avoid SELECT *.
Also provide:
- goal: a short description of the analytical purpose of the query
Return a structured JSON response.
""".strip()

_SQL_RULES = """
Important SQL rules:
- Use Trino SQL syntax.
- Use only the selected tables.
- Use only columns that appear in the DDL context.
- Use only the listed join rules.
- Do not invent tables, columns, or join keys.
- Avoid SELECT *.
- Columns ending in *_date_sk are integer surrogate keys, not DATE values.
- Only filter on DATE literals via a DATE-typed column shown in the DDL context.
- Do not use SELECT aliases in GROUP BY, WHERE, or HAVING.
- If a derived expression is selected and also grouped, repeat the full expression in GROUP BY or use a CTE/subquery.
- After defining a CTE or subquery alias, only reference columns explicitly projected by that CTE/subquery.
- Preserve original column names carefully when moving columns through CTEs.
- After joining tables, CTEs, or subqueries, qualify column names when the same column name may exist on both sides of the join.
- Do not reference unqualified columns if they are available from multiple joined sources.
""".strip()


# ------------------------------------------------------------
# CHANGE-2 + CHANGE-6 state: cross-batch diversity tracker
# ------------------------------------------------------------

class DiversityTracker:
    """
    Thread-safe memory of what has been generated so far in this process.

    Feeds two mechanisms:
      * CHANGE-2 -- ``table_usage`` biases the connected walk toward
        under-used tables (SQL-Factory Eq. 7 / DiGiT coverage re-biasing).
      * CHANGE-6 -- ``seen_sql`` / ``skeletons`` reject exact duplicates and
        over-represented query shapes (SQLStorm dedup / SQL-Factory
        Critical Agent).

    A module-level default instance is shared across ``generate_query_batch``
    calls, so the batched loop in ``Lakehouse.generate_workload`` accumulates
    coverage over the whole run without any API change.
    """

    def __init__(self):
        self.lock = threading.Lock()
        self.table_usage: Counter = Counter()
        self.seen_sql: set[str] = set()
        self.skeletons: Counter = Counter()

    def usage_snapshot(self) -> dict[str, int]:
        with self.lock:
            return dict(self.table_usage)

    def try_accept(
        self,
        *,
        sql_key: str,
        skeleton,
        tables: list[str],
        skeleton_cap: int,
        enforce_skeleton_cap: bool = True,
    ) -> str:
        """
        Atomically test-and-record a candidate.
        Returns "accepted", "duplicate", or "skeleton_capped".
        """
        with self.lock:
            if sql_key in self.seen_sql:
                return "duplicate"
            if enforce_skeleton_cap and self.skeletons[skeleton] >= skeleton_cap:
                return "skeleton_capped"
            self.seen_sql.add(sql_key)
            self.skeletons[skeleton] += 1
            self.table_usage.update(tables)
            return "accepted"

    def reset(self):
        with self.lock:
            self.table_usage.clear()
            self.seen_sql.clear()
            self.skeletons.clear()


_DEFAULT_TRACKER = DiversityTracker()

# CHANGE-4: cache of sampled column values, shared across batches like the
# tracker (one value-sampling query per column per process, prompts then draw
# random subsets so aid lines still vary per query).
_VALUE_CACHE: dict[tuple[str, str], list] = {}
_VALUE_CACHE_LOCK = threading.Lock()


def _dedup_key(sql: str) -> str:
    # same normalisation SQLStorm uses before selection
    return re.sub(r"\s+", " ", sql.strip().lower())


def _skeleton_key(sql: str):
    """
    Coarse structural skeleton via the same feature extractor the evaluation
    reports use (sql_features.query_features), so the notion of "shape" the
    generator diversifies is exactly the notion the metrics measure.
    """
    f = query_features(sql)

    def n(key):
        return int(f.get(key, 0) or 0)

    return (
        min(n("num_tables"), 6),
        min(n("num_joins"), 6),
        n("num_group_by") > 0,
        n("num_order_by") > 0,
        min(n("num_subqueries"), 3),
        min(n("num_ctes"), 3),
        n("num_window_functions") > 0,
        n("num_set_operations") > 0,
        n("num_having") > 0,
        n("num_distinct") > 0,
        n("num_case_when") > 0,
    )


# ------------------------------------------------------------
# CHANGE-1 + CHANGE-2: mixed, coverage-aware table sampling
# ------------------------------------------------------------

def sample_tables_v2(
    schema: dict,
    n_tables: int,
    *,
    rng: random.Random,
    table_usage: dict[str, int] | None = None,
    connected_fraction: float = 0.5,
) -> tuple[list[str], str]:
    """
    Returns (tables, mode) where mode is "connected" or "uniform".

    "uniform" (E2ETune diversity control 1): a uniform random subset with no
    connectivity constraint -- maximises table entropy and unique table sets.
    The prompt handles subsets with no direct joins ("No direct joins
    available."), which also yields single-table / non-join query shapes v1
    never produced.

    "connected" (v1's walk, re-weighted): guarantees a joinable subset, but
    both the start table and every expansion step are drawn with weight
    1 / (1 + usage) so hub tables stop dominating once they have been used
    (SQL-Factory Eq. 7 / DiGiT re-biasing).
    """
    all_tables = extract_schema_tables(schema)
    n_tables = min(n_tables, len(all_tables))
    usage = table_usage or {}

    def weight(t: str) -> float:
        return 1.0 / (1.0 + usage.get(t, 0))

    if rng.random() >= connected_fraction:
        return sorted(rng.sample(all_tables, k=n_tables)), "uniform"

    graph = build_relationship_graph(schema)

    start = rng.choices(all_tables, weights=[weight(t) for t in all_tables], k=1)[0]
    selected = {start}
    frontier = set(graph.get(start, set()))

    while frontier and len(selected) < n_tables:
        candidates = sorted(frontier)  # sort for seed reproducibility
        pick = rng.choices(candidates, weights=[weight(t) for t in candidates], k=1)[0]
        selected.add(pick)
        frontier |= set(graph.get(pick, set()))
        frontier -= selected

    return sorted(selected), "connected"


# ------------------------------------------------------------
# CHANGE-4: Predicate Generation Aid (E2ETune component 4)
# ------------------------------------------------------------

def sample_column_values(
    *,
    conn_factory,
    catalog: str,
    schema: str,
    table: str,
    column: str,
    limit: int = 20,
) -> list:
    """Sample distinct non-null values for one column. Best-effort: [] on error."""
    conn = conn_factory()
    try:
        cur = conn.cursor()
        try:
            cur.execute(
                f"SELECT DISTINCT {column} FROM {catalog}.{schema}.{table} "
                f"WHERE {column} IS NOT NULL LIMIT {int(limit)}"
            )
            return [r[0] for r in cur.fetchall()]
        finally:
            cur.close()
    except Exception:
        return []
    finally:
        try:
            conn.close()
        except Exception:
            pass


def _cached_column_values(
    *,
    conn_factory,
    catalog: str,
    schema: str,
    table: str,
    column: str,
    value_cache: dict,
    value_cache_lock,
) -> list:
    key = (table, column)
    with value_cache_lock:
        cached = value_cache.get(key)
    if cached is not None:
        return cached

    vals = sample_column_values(
        conn_factory=conn_factory,
        catalog=catalog,
        schema=schema,
        table=table,
        column=column,
    )
    with value_cache_lock:
        value_cache.setdefault(key, vals)
        return value_cache[key]


def _format_value(v) -> str:
    s = str(v)
    return s if len(s) <= 60 else s[:57] + "..."


def build_value_aid(
    *,
    conn_factory,
    catalog: str,
    schema: str,
    tables: list[str],
    columns_by_table: dict[str, list[dict]],
    rng: random.Random,
    value_cache: dict,
    value_cache_lock,
    max_cols: int = 6,
    max_vals: int = 5,
) -> str:
    """
    Random "table.column (type): v1, v2, ..." lines. Randomising which
    columns/values are shown per query is E2ETune's second diversity lever:
    it spreads predicates across the column space (their column coverage:
    0.889 vs v1's 0.694) and grounds literals in real data.
    """
    lines: list[str] = []
    budget = max_cols
    shuffled_tables = list(tables)
    rng.shuffle(shuffled_tables)

    for table in shuffled_tables:
        if budget <= 0:
            break
        cols = list(columns_by_table.get(table, []))
        rng.shuffle(cols)
        for col in cols[:2]:  # at most 2 columns per table so aid spans tables
            if budget <= 0:
                break
            vals = _cached_column_values(
                conn_factory=conn_factory,
                catalog=catalog,
                schema=schema,
                table=table,
                column=col["name"],
                value_cache=value_cache,
                value_cache_lock=value_cache_lock,
            )
            if not vals:
                continue
            shown = rng.sample(vals, k=min(max_vals, len(vals)))
            lines.append(
                f"- {table}.{col['name']} ({col['type']}): "
                + ", ".join(_format_value(v) for v in shown)
            )
            budget -= 1

    if not lines:
        return ""
    return (
        "Example column values (sampled from the live data; use them to "
        "write realistic, varied predicates):\n" + "\n".join(lines)
    )


# ------------------------------------------------------------
# Prompt context
# ------------------------------------------------------------

def build_schema_context(
    schema: dict,
    selected_tables: list[str],
    ddl_context: str | None = None,
    value_aid: str = "",
) -> str:
    relationships = get_relevant_relationships(schema, selected_tables)
    relationship_lines = [f"- {relationship_to_text(rel)}" for rel in relationships]
    ddl_block = ddl_context.strip() if ddl_context else "No DDL provided."
    aid_block = f"\n\n{value_aid}" if value_aid else ""

    return f"""
Dataset:
- {schema.get("name", "unknown")}
- Tables are Iceberg tables queried through Trino.

Selected tables:
{chr(10).join(f"- {table}" for table in selected_tables)}

DDL context:
{ddl_block}

Valid join rules:
{chr(10).join(relationship_lines) if relationship_lines else "- No direct joins available."}{aid_block}

{_SQL_RULES}
""".strip()


# ------------------------------------------------------------
# Low-level SQL generation (v1's structured-output call, with the
# variant task injected and CHANGE-5 temperature jitter applied)
# ------------------------------------------------------------

_OUTPUT_SCHEMA = {
    "type": "json_schema",
    "name": "sql_generation_result",
    "strict": True,
    "schema": {
        "type": "object",
        "properties": {
            "sql": {
                "type": "string",
                "description": "The generated Trino SQL query.",
            },
            "goal": {
                "type": "string",
                "description": "A short description of the analytical goal of the query.",
            },
            "tables_used": {"type": "array", "items": {"type": "string"}},
            "columns_used": {"type": "array", "items": {"type": "string"}},
        },
        "required": ["sql", "goal", "tables_used", "columns_used"],
        "additionalProperties": False,
    },
}


def generate_sql(
    client: OpenAI,
    schema_context: str,
    *,
    task: str,
    reasoning: str = "medium",
    model_name: str = MODEL_NAME,
    temperature: float = 0.6,
) -> dict:
    def _call():
        return client.responses.create(
            model=model_name,
            instructions=INSTRUCTIONS_TEMPLATE,
            input=PROMPT_TEMPLATE.format(schema_context=schema_context, task=task),
            reasoning={"effort": reasoning},
            text={"format": _OUTPUT_SCHEMA},
            temperature=temperature,
            store=False,
        )

    result = call_with_retry(_call)
    data = json.loads(result.output_text)
    return normalise_sql_result(data)


# ------------------------------------------------------------
# Higher-level generation pipeline (same signatures as v1)
# ------------------------------------------------------------

def generate_query(
    *,
    conn_factory,
    schema_json: dict,
    catalog: str,
    trino_schema: str,
    client: OpenAI,
    model_name: str = MODEL_NAME,
    temperature: float = 0.6,
    reasoning: str = "medium",
    min_tables: int = 2,
    max_tables: int = 8,
    random_seed: int | None = None,
    ddl_cache: dict[str, list[dict]] | None = None,
    ddl_cache_lock: LockType | None = None,
    # v2-only optional knobs (defaults preserve the drop-in API)
    tracker: DiversityTracker | None = None,
    connected_fraction: float = 0.5,
    value_cache: dict | None = None,
    value_cache_lock=None,
    variant: dict | None = None,
) -> dict:
    """
    Full single-query pipeline:
      1. draw a prompt variant                     (CHANGE-3)
      2. sample tables: mixed connected/uniform,
         coverage-weighted                          (CHANGE-1, CHANGE-2)
      3. fetch DDL context (shared cache, as v1)
      4. sample live column values for the aid      (CHANGE-4)
      5. call the model with jittered temperature   (CHANGE-5)
      6. return rich metadata (superset of v1's)
    """
    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()
    if tracker is None:
        tracker = _DEFAULT_TRACKER
    if value_cache is None:
        value_cache = _VALUE_CACHE
    if value_cache_lock is None:
        value_cache_lock = _VALUE_CACHE_LOCK

    rng = random.Random(random_seed)
    n_tables = rng.randint(min_tables, max_tables)

    if variant is None:
        variant = rng.choice(PROMPT_VARIANTS)

    selected_tables, sampling_mode = sample_tables_v2(
        schema_json,
        n_tables,
        rng=rng,
        table_usage=tracker.usage_snapshot(),
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

    # column metadata comes from the same DDL cache -- no extra fetches
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
    )

    schema_context = build_schema_context(
        schema=schema_json,
        selected_tables=selected_tables,
        ddl_context=ddl_context,
        value_aid=value_aid,
    )

    # CHANGE-5: jitter around the caller's temperature, clamped to [0.0, 1.0]
    query_temperature = min(1.0, max(0.0, temperature + variant["temp_delta"]))

    sql_result = generate_sql(
        client=client,
        schema_context=schema_context,
        task=variant["task"],
        model_name=model_name,
        temperature=query_temperature,
        reasoning=reasoning,
    )

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
        # v2 metadata
        "prompt_variant": variant["name"],
        "sampling_mode": sampling_mode,
    }


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
    ddl_cache_lock: LockType | None = None,
    generation_workers: int = 4,
    # v2-only optional knobs (defaults preserve the drop-in API)
    tracker: DiversityTracker | None = None,
    connected_fraction: float = 0.5,
    skeleton_cap: int = 12,
    max_attempt_factor: float = 3.0,
) -> list[dict]:
    """
    Batch generation with CHANGE-6 novelty control at acceptance time:
    exact duplicates (normalised SQL text, as SQLStorm dedups) are always
    rejected; candidates whose structural skeleton already has
    ``skeleton_cap`` accepted queries are rejected and their slot regenerated
    (the SQL-Factory Critical-Agent role), within a total attempt budget of
    ``num_queries * max_attempt_factor``. If the budget runs out, capped
    (but still textually unique) candidates are used as filler so the caller
    still receives ``num_queries`` queries -- diversity degrades gracefully
    rather than the run stalling.

    The default ``tracker`` is module-level, so the repeated batch calls made
    by ``Lakehouse.generate_workload``'s validation loop share coverage and
    novelty state across the whole workload.
    """
    rng = random.Random(random_seed)

    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()
    if tracker is None:
        tracker = _DEFAULT_TRACKER

    thread_local = threading.local()

    def get_client():
        if not hasattr(thread_local, "client"):
            thread_local.client = client_factory()
        return thread_local.client

    def worker(seed: int) -> dict:
        return generate_query(
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

    accepted: list[dict] = []
    overflow: list[dict] = []  # skeleton-capped but textually unique
    attempts = 0
    max_attempts = max(num_queries, math.ceil(num_queries * max_attempt_factor))
    rejected_duplicate = 0
    rejected_skeleton = 0

    while len(accepted) < num_queries and attempts < max_attempts:
        need = min(num_queries - len(accepted), max_attempts - attempts)
        seeds = [rng.randint(0, 10**9) for _ in range(need)]
        attempts += need

        with ThreadPoolExecutor(max_workers=min(generation_workers, need)) as executor:
            futures = [executor.submit(worker, seed) for seed in seeds]
            time.sleep(0.1)

            for future in as_completed(futures):
                try:
                    q = future.result()
                except Exception as e:
                    print(f"[generation failed] {type(e).__name__}: {e}")
                    continue

                sql = q.get("sql", "")
                if not sql:
                    continue

                verdict = tracker.try_accept(
                    sql_key=_dedup_key(sql),
                    skeleton=_skeleton_key(sql),
                    tables=q.get("selected_tables", []),
                    skeleton_cap=skeleton_cap,
                )

                if verdict == "accepted":
                    accepted.append(q)
                elif verdict == "skeleton_capped":
                    rejected_skeleton += 1
                    overflow.append(q)
                else:
                    rejected_duplicate += 1

    # graceful degradation: fill any shortfall from capped-but-unique queries
    while len(accepted) < num_queries and overflow:
        q = overflow.pop(0)
        verdict = tracker.try_accept(
            sql_key=_dedup_key(q["sql"]),
            skeleton=_skeleton_key(q["sql"]),
            tables=q.get("selected_tables", []),
            skeleton_cap=skeleton_cap,
            enforce_skeleton_cap=False,
        )
        if verdict == "accepted":
            accepted.append(q)

    if rejected_duplicate or rejected_skeleton:
        print(
            f"[novelty control] rejected {rejected_duplicate} duplicates, "
            f"{rejected_skeleton} skeleton-capped candidates "
            f"({attempts} attempts for {len(accepted)} queries)"
        )

    return accepted


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
    """
    Same artefact layout as v1 (q<i>.sql + generation_report.json). The report
    additionally records each query's prompt variant and sampling mode, plus
    the variant/mode mix -- so the effect of CHANGE-1/3 is auditable per run.
    """
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

    report = {
        "workload_name": workload_name,
        "workload_dir": str(workload_dir),
        "generator": "query_generator_v2",
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
            "variants": {v["name"]: v["task"] for v in PROMPT_VARIANTS},
            "semantic_fields": ["goal"],
        },
        "diversity_mechanisms": {
            "mixed_table_sampling": "connected FK walk / uniform random subset (E2ETune)",
            "coverage_aware_seeding": "1/(1+usage) table weighting (SQL-Factory Eq. 7, DiGiT)",
            "prompt_variant_suite": "graded-complexity task variants (SQLStorm P1-P7)",
            "predicate_value_aid": "sampled live column values (E2ETune component 4)",
            "temperature_jitter": "per-variant delta on base temperature (SQLStorm temp 1.0)",
            "novelty_control": "normalised-SQL dedup + skeleton cap (SQLStorm dedup, SQL-Factory Critical Agent)",
            "prompt_variant_mix": dict(variant_mix),
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
