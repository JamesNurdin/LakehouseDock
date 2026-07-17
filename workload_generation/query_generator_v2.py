"""
query_generator_v2 -- diversity-aware, profile-calibrated QueryDock generator.

Drop-in replacement for ``query_generator`` (v1). The public API is identical
-- it exports every name ``Lakehouse`` imports from v1::

    load_schema, make_openai_client, warm_up_model,
    generate_query, generate_query_batch, write_workload_directory,
    fetch_table_columns, fetch_schema_table_columns

so swapping ``workload_generation.query_generator`` for
``workload_generation.query_generator_v2`` in ``trino_stack/lakehouse.py`` is
the only change required. All v1 helpers that are unchanged are re-used (not
copied) from v1.

Evaluation target
-----------------
``Workloads/tpcds_generator_analysis.ipynb`` scores a generator on two axes
simultaneously:

  * **fidelity** -- mean absolute relative error (MARE) of every
    ``meta_*_mean`` feature against the real TPC-DS workload, plus the L1
    distance of the low/medium/high complexity mix to the real 13/74/13;
  * **diversity** -- plan-graph Vendi score, plan uniqueness, min/mean
    nearest-neighbour distance, join-edge & column coverage, operator
    n-grams, skeleton ratio.

A generator therefore has to *look like* the reference workload per query
while *not repeating itself* across queries.

History: what v2.0 got right and wrong
--------------------------------------
v1 used one fixed prompt + a hub-biased connected walk: high validity but
mode-collapsed (skeleton ratio 0.253, NN distance 0.186, table entropy
0.896). v2.0 added the baselines' diversity mechanisms and they worked --
table entropy 0.938, 90/100 unique table sets, join-edge coverage 0.805, all
at or near the top of the 100-query comparison. But v2.0 also caused a
*complexity collapse*: 45% low-complexity queries vs the real 13%, joins
2.7 vs 5.5, query length halved. That collapse capped exactly the metrics
the notebook cares about: column coverage (small queries touch few columns),
Vendi / NN distance (small plans look alike -- v2.0 had 100/100 unique SQL
but only 88/100 unique plan graphs and min-NN 0.0), and MARE (every mean
drifted to ~half the real value). Root causes, confirmed against the
baselines: (a) uniform table subsets are frequently unjoinable in a
snowflake schema, and with the "only listed join rules" guardrail the model
degenerates to one-table queries; (b) the non-triviality steering line was
removed wholesale -- E2ETune keeps a "produce a non-trivial analytical
query" floor and does not collapse; (c) the variant suite was tilted simple
(SQLStorm asks for "interesting and elaborate" in 5/7 prompts, v2.0 in 2/7).

Mechanisms (tags mark the implementation sites)
-----------------------------------------------
Kept from v2.0 (validated by the 100-query run):

CHANGE-1  Mixed table sampling (connected walk / uniform subset), for table
          entropy and unique table sets (E2ETune diversity control 1).
CHANGE-2  Coverage-aware ``1/(1+usage)`` weighting of the walk
          (SQL-Factory Eq. 7, DiGiT re-biasing).
CHANGE-4  Predicate Generation Aid: live sampled column values in the prompt
          (E2ETune component 4) -- grounds literals, spreads predicate
          columns.
CHANGE-5  Per-variant temperature jitter (SQLStorm generates hot).
CHANGE-6  Acceptance-time novelty control: normalised-SQL dedup + skeleton
          cap (SQLStorm dedup, SQL-Factory Critical Agent).

New in v2.1 (fixes for the complexity collapse + fidelity targeting):

V2.1-A  **Profile-calibrated shape sampling** replaces the uniform draw over
        7 fixed variants. Each query draws a weighted *family* (simple /
        core analytical / windows / nested aggregation / set operations /
        multi-role deep joins / string+regex) plus Bernoulli *add-on*
        constructs (CTE, subquery, HAVING, DISTINCT, ORDER BY, LIMIT, ...).
        Family weights and add-on probabilities are calibrated so the
        *expected* per-query feature means and the SQLStorm complexity mix
        land on the reference workload's profile (13/74/13 for TPC-DS:
        ``simple`` maps to "low" -- <=3 joins, no subquery/window/set-op;
        ``multi_role_joins`` (>8 joins) and ``string_regex`` (regex) map to
        "high" under ``sql_features.classify_complexity``; everything else
        is "medium"). This is SQLBarber's idea -- generate against a target
        distribution -- applied to structural features instead of cost.
        The combinatorial family x add-on space also yields far more
        distinct skeletons than 7 fixed prompts (Vendi / skeleton ratio).

V2.1-B  **Connectivity-guaranteed uniform sampling**: the uniform mode
        rejection-samples subsets until the induced FK subgraph is
        connected (falling back to largest-component + top-up). Keeps the
        entropy/unique-set gains of E2ETune-style sampling while eliminating
        the unjoinable sets that produced v2.0's one-table queries.

V2.1-C  **Non-triviality floor restored** (E2ETune's exact device): unless
        the task explicitly asks for a simple query, the model must produce
        a non-trivial analytical query and vary its shape from previous
        queries. Non-simple tasks also require joining *all* selected
        tables (DiGiT's "use all of these tables"), which pins
        joins-per-query to the sampled table count -- the single biggest
        MARE lever (real TPC-DS: 5.5 joins/query).

V2.1-D  **Join-edge-coverage-aware walk**: the connected walk weights
        candidate tables by the least-used FK edge that would connect them,
        so under-covered edges get exercised (join_edge_coverage ↑,
        join-edge entropy ↑) -- DiGiT's coverage-gap filling at edge
        granularity.

V2.1-E  **Column-coverage-aware value aid**: the aid prefers columns the
        workload has not yet used (tracked from the model's reported
        ``columns_used``), pushing column coverage instead of re-showing
        the same columns (column coverage is a headline notebook metric).

V2.1-F  **Near-duplicate rejection at plan granularity proxy**: in addition
        to the skeleton cap, a candidate whose (skeleton, table-set) pair
        has already been accepted is rejected and regenerated. Two queries
        with the same coarse structure over the same tables are exactly the
        ones that collide as identical plan graphs (v2.0: min-NN 0.0,
        12/100 duplicate plans); E2ETune@100 had zero plan duplicates and
        the notebook plots min-NN directly.

What is deliberately kept from v1
---------------------------------
The validity guardrails (don't invent tables/columns/join keys, qualify
ambiguous columns, the ``*_date_sk`` note, CTE projection rules): they give
QueryDock its 100% EXPLAIN pass rate and constrain no notebook metric.
"""

from __future__ import annotations

import json
import math
import random
import re
import threading
import time

from collections import Counter, deque
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
    "ADDON_SPECS",
]

GENERATOR_VERSION = "query_generator_v2.1"


# ------------------------------------------------------------
# V2.1-A: profile-calibrated shape sampling
# ------------------------------------------------------------
# Families are drawn by weight; weights are calibrated so the SQLStorm-style
# complexity mix lands on the reference workload's 13/74/13
# (sql_features.classify_complexity: "low" = <=3 joins and no
# subquery/window/set-op; "high" = regex/unnest/recursion or >8 joins;
# otherwise "medium"):
#
#   simple           0.13 -> "low"     (<=1 join, no subquery/window/set-op)
#   core_analytical  0.44 -> "medium"  (join-all with ~4 joins > 3)
#   windows_ranking  0.11 -> "medium"  (window function)
#   nested_agg       0.11 -> "medium"  (subquery/CTE)
#   set_operations   0.08 -> "medium"  (set operation)
#   multi_role_joins 0.08 -> "high"    (>8 join clauses via role aliases)
#   string_regex     0.05 -> "high"    (regexp_like / regexp_extract)
#
# ``n_tables`` overrides keep the tables-per-query mean near the reference
# (~5.5): simple queries use 1-2 tables (real TPC-DS min is 1), deep-join
# queries use the top of the caller's range.
#
# Task templates take {n_tables} and {k_predicates}; the predicate floor
# (3-6, sampled per query) plus ~4 join conditions reproduces the reference
# predicate mean (~15) instead of v2.0's 5.8.

PROMPT_VARIANTS: list[dict] = [
    {
        "name": "simple",
        "weight": 0.13,
        "temp_delta": -0.2,
        "n_tables_range": (1, 2),
        "join_all": False,
        "task": (
            "Generate one simple SQL query: scan one table (or two tables "
            "with a single join), apply one or two selective filter "
            "predicates using realistic literals, and project a small set "
            "of columns, optionally with one aggregate. Do not use "
            "subqueries, window functions, or set operations."
        ),
    },
    {
        "name": "core_analytical",
        "weight": 0.44,
        "temp_delta": 0.0,
        "n_tables_range": None,
        "join_all": True,
        "task": (
            "Generate one analytical SQL query that joins all {n_tables} "
            "selected tables using only the listed join rules, applies at "
            "least {k_predicates} selective filter predicates with "
            "realistic literals, and groups and aggregates measures "
            "(SUM / AVG / COUNT / MIN / MAX)."
        ),
    },
    {
        "name": "windows_ranking",
        "weight": 0.11,
        "temp_delta": +0.2,
        "n_tables_range": None,
        "join_all": True,
        "task": (
            "Generate one analytical SQL query that joins all {n_tables} "
            "selected tables using only the listed join rules, applies at "
            "least {k_predicates} filter predicates, and ranks or compares "
            "rows with window functions (RANK, DENSE_RANK, ROW_NUMBER, or "
            "moving aggregates over a window frame), optionally combined "
            "with CASE WHEN logic."
        ),
    },
    {
        "name": "nested_aggregation",
        "weight": 0.11,
        "temp_delta": +0.1,
        "n_tables_range": None,
        "join_all": True,
        "task": (
            "Generate one analytical SQL query that joins all {n_tables} "
            "selected tables using only the listed join rules, aggregates "
            "in a CTE or derived subquery, and then aggregates or filters "
            "over that result again (e.g. an average of per-group sums, or "
            "HAVING against a derived aggregate). Apply at least "
            "{k_predicates} filter predicates."
        ),
    },
    {
        "name": "set_operations",
        "weight": 0.08,
        "temp_delta": +0.2,
        "n_tables_range": None,
        "join_all": False,
        "task": (
            "Generate one analytical SQL query built around a set operation "
            "(UNION, UNION ALL, INTERSECT, or EXCEPT) that combines two or "
            "more sub-selects over the selected tables, each with joins and "
            "filter predicates where the join rules allow."
        ),
    },
    {
        "name": "multi_role_joins",
        "weight": 0.08,
        "temp_delta": +0.2,
        "n_tables_range": "high",
        "join_all": True,
        "task": (
            "Generate one deep-join analytical SQL query: join all "
            "{n_tables} selected tables using the listed join rules, and "
            "additionally reuse at least two of the tables under different "
            "aliases in different roles (for example, the same dimension "
            "joined twice through the same join rule for two different "
            "purposes), so that the query contains at least 9 join clauses "
            "in total. Aggregate and group the result. If 9 joins are not "
            "achievable with the listed rules, use as many as they allow."
        ),
    },
    {
        "name": "string_regex",
        "weight": 0.05,
        "temp_delta": +0.2,
        "n_tables_range": None,
        "join_all": False,
        "task": (
            "Generate one analytical SQL query that exercises string "
            "processing on the selected tables: use regexp_like or "
            "regexp_extract on a text column, plus LIKE pattern matching, "
            "concatenation, or substring manipulation in predicates and "
            "projections, combined with joins and aggregation where the "
            "join rules allow."
        ),
    },
]

# Add-on constructs appended to the family task (V2.1-A). Probabilities are
# calibrated to the reference workload's per-query feature means (TPC-DS:
# ctes 0.64, subqueries 1.54, windows 0.27, having 0.11, distinct 0.23,
# order_by 1.08, limit 0.85, case_when 1.30, set_ops 0.42). ``simple_ok``
# marks add-ons that do not change the complexity class, so the "simple"
# family keeps classifying as "low".
ADDON_SPECS: list[dict] = [
    {"name": "cte", "p": 0.35, "simple_ok": False,
     "line": "Structure part of the query as a CTE (WITH clause)."},
    {"name": "subquery", "p": 0.45, "simple_ok": False,
     "line": "Include at least one subquery (scalar, IN, or EXISTS)."},
    {"name": "window", "p": 0.10, "simple_ok": False, "skip_families": ["windows_ranking"],
     "line": "Include one window function."},
    {"name": "set_op", "p": 0.05, "simple_ok": False, "skip_families": ["set_operations"],
     "line": "Combine two sub-selects with a set operation."},
    {"name": "case_when", "p": 0.30, "simple_ok": False,
     "line": "Use a CASE WHEN expression in the projection or aggregation."},
    {"name": "having", "p": 0.12, "simple_ok": False,
     "line": "Filter groups with a HAVING clause."},
    {"name": "distinct", "p": 0.18, "simple_ok": True,
     "line": "Use DISTINCT somewhere meaningful."},
    {"name": "order_by", "p": 0.75, "simple_ok": True,
     "line": "Order the final result."},
    {"name": "limit", "p": 0.85, "simple_ok": True,
     "line": "End the query with LIMIT 100."},
]


def sample_shape_spec(rng: random.Random) -> dict:
    """Draw a weighted family + add-on constructs (V2.1-A)."""
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

    return {"family": family, "addons": addons}


def build_task_text(spec: dict, *, n_tables: int, rng: random.Random,
                    has_join_rules: bool) -> str:
    family = spec["family"]
    k_predicates = rng.randint(3, 6)
    task = family["task"].format(n_tables=n_tables, k_predicates=k_predicates)

    # a join-all instruction is meaningless for a subset with no FK edges;
    # V2.1-B makes that rare, but single-table draws still occur (simple)
    if not has_join_rules and family["join_all"]:
        task += " If no join rules are listed, use the tables independently."

    lines = [spec_line["line"] for spec_line in spec["addons"]]
    if lines:
        task += "\nAdditionally:\n" + "\n".join(f"- {l}" for l in lines)
    return task


PROMPT_TEMPLATE = """
Schema context:
{schema_context}

Task:
{task}
""".strip()

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

# V2.1-C: the non-triviality floor is restored using E2ETune's exact device
# ("produce a non-trivial analytical query ... vary the query shape"),
# conditioned so the calibrated "simple" family is still allowed to be
# simple. The validity guardrails are v1's, minus the "join to date_dim"
# instruction that reinforced hub bias.
_SQL_RULES = """
Important SQL rules:
- Use Trino SQL syntax.
- Use only the selected tables.
- Use only columns that appear in the DDL context.
- Use only the listed join rules.
- Do not invent tables, columns, or join keys.
- Avoid SELECT *.
- Unless the task explicitly asks for a simple query, produce a non-trivial analytical query (joins, filtering, grouping, aggregation and/or ordering) and vary the query shape from previous queries.
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
# CHANGE-2 + CHANGE-6 + V2.1-D/E/F state: cross-batch diversity tracker
# ------------------------------------------------------------

def _edge_key(a: str, b: str) -> tuple[str, str]:
    return (a, b) if a <= b else (b, a)


class DiversityTracker:
    """
    Thread-safe memory of what has been generated so far in this process.

    Feeds four mechanisms:
      * CHANGE-2 -- ``table_usage`` biases the connected walk toward
        under-used tables (SQL-Factory Eq. 7 / DiGiT re-biasing).
      * V2.1-D  -- ``edge_usage`` biases the walk toward under-used FK edges
        (join-edge coverage).
      * V2.1-E  -- ``column_usage`` biases the value aid toward columns the
        workload has not touched yet (column coverage).
      * CHANGE-6 / V2.1-F -- ``seen_sql`` / ``skeletons`` / ``seen_fine``
        reject exact duplicates, over-represented shapes, and
        (skeleton, table-set) near-duplicates that collide as identical
        plan graphs.

    A module-level default instance is shared across ``generate_query_batch``
    calls, so the batched loop in ``Lakehouse.generate_workload`` accumulates
    state over the whole workload without any API change.
    """

    def __init__(self):
        self.lock = threading.Lock()
        self.table_usage: Counter = Counter()
        self.edge_usage: Counter = Counter()
        self.column_usage: Counter = Counter()
        self.seen_sql: set[str] = set()
        self.skeletons: Counter = Counter()
        self.seen_fine: set = set()

    def usage_snapshot(self) -> dict:
        with self.lock:
            return {
                "tables": dict(self.table_usage),
                "edges": dict(self.edge_usage),
                "columns": dict(self.column_usage),
            }

    def try_accept(
        self,
        *,
        sql_key: str,
        skeleton,
        tables: list[str],
        skeleton_cap: int,
        edges: list[tuple[str, str]] = (),
        columns: list[str] = (),
        enforce_caps: bool = True,
    ) -> str:
        """
        Atomically test-and-record a candidate. Returns "accepted",
        "duplicate", "skeleton_capped", or "near_duplicate".
        """
        fine_key = (skeleton, tuple(sorted(tables)))
        with self.lock:
            if sql_key in self.seen_sql:
                return "duplicate"
            if enforce_caps:
                if fine_key in self.seen_fine:
                    return "near_duplicate"
                if self.skeletons[skeleton] >= skeleton_cap:
                    return "skeleton_capped"
            self.seen_sql.add(sql_key)
            self.seen_fine.add(fine_key)
            self.skeletons[skeleton] += 1
            self.table_usage.update(tables)
            self.edge_usage.update(edges)
            self.column_usage.update(columns)
            return "accepted"

    def reset(self):
        with self.lock:
            self.table_usage.clear()
            self.edge_usage.clear()
            self.column_usage.clear()
            self.seen_sql.clear()
            self.skeletons.clear()
            self.seen_fine.clear()


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


def _bare_column_name(name: str) -> str:
    return name.rsplit(".", 1)[-1].strip().lower()


# ------------------------------------------------------------
# CHANGE-1 + CHANGE-2 + V2.1-B/D: mixed, coverage-aware table sampling
# ------------------------------------------------------------

def _is_connected(subset: set[str], graph) -> bool:
    if len(subset) <= 1:
        return True
    start = next(iter(subset))
    seen = {start}
    queue = deque([start])
    while queue:
        cur = queue.popleft()
        for nb in graph.get(cur, set()):
            if nb in subset and nb not in seen:
                seen.add(nb)
                queue.append(nb)
    return len(seen) == len(subset)


def _largest_component(subset: set[str], graph) -> set[str]:
    remaining = set(subset)
    best: set[str] = set()
    while remaining:
        start = next(iter(remaining))
        comp = {start}
        queue = deque([start])
        while queue:
            cur = queue.popleft()
            for nb in graph.get(cur, set()):
                if nb in remaining and nb not in comp:
                    comp.add(nb)
                    queue.append(nb)
        if len(comp) > len(best):
            best = comp
        remaining -= comp
    return best


def sample_tables_v2(
    schema: dict,
    n_tables: int,
    *,
    rng: random.Random,
    table_usage: dict[str, int] | None = None,
    edge_usage: dict[tuple[str, str], int] | None = None,
    connected_fraction: float = 0.5,
    max_uniform_tries: int = 40,
) -> tuple[list[str], str]:
    """
    Returns (tables, mode) where mode is "connected" or "uniform".

    Both modes now guarantee a *joinable* subset (V2.1-B): v2.0's
    unconstrained uniform draws frequently induced zero FK edges in a
    snowflake schema, and with the "only listed join rules" guardrail the
    model degenerated to one-table queries -- the root cause of the
    complexity collapse (45% low vs the real 13%).

    "uniform": rejection-sample uniform subsets until the induced FK
    subgraph is connected (largest-component + top-up as fallback). Keeps
    E2ETune-style table entropy without the degenerate sets.

    "connected": v1's walk, re-weighted. Start table and expansion steps are
    drawn with weight 1/(1+table_usage) (CHANGE-2), multiplied by
    1/(1+usage of the least-used FK edge that connects the candidate to the
    current selection) (V2.1-D) so under-covered join edges get exercised.
    """
    all_tables = extract_schema_tables(schema)
    n_tables = min(n_tables, len(all_tables))
    t_usage = table_usage or {}
    e_usage = edge_usage or {}
    graph = build_relationship_graph(schema)

    def table_weight(t: str) -> float:
        return 1.0 / (1.0 + t_usage.get(t, 0))

    if n_tables <= 1:
        start = rng.choices(all_tables, weights=[table_weight(t) for t in all_tables], k=1)[0]
        return [start], "uniform"

    if rng.random() >= connected_fraction:
        subset: set[str] = set()
        for _ in range(max_uniform_tries):
            cand = set(rng.sample(all_tables, k=n_tables))
            if _is_connected(cand, graph):
                return sorted(cand), "uniform"
            subset = cand
        # fallback: largest connected component of the last draw, topped up
        # along FK edges so the result stays joinable
        comp = _largest_component(subset, graph)
        while len(comp) < n_tables:
            frontier = sorted(set().union(*(graph.get(t, set()) for t in comp)) - comp)
            if not frontier:
                break
            comp.add(rng.choices(frontier, weights=[table_weight(t) for t in frontier], k=1)[0])
        return sorted(comp), "uniform"

    def combined_weight(t: str, selected: set[str]) -> float:
        edge_uses = [
            e_usage.get(_edge_key(t, s), 0)
            for s in selected
            if s in graph.get(t, set())
        ]
        least_used_edge = min(edge_uses) if edge_uses else 0
        return table_weight(t) / (1.0 + least_used_edge)

    start = rng.choices(all_tables, weights=[table_weight(t) for t in all_tables], k=1)[0]
    selected = {start}
    frontier = set(graph.get(start, set()))

    while frontier and len(selected) < n_tables:
        candidates = sorted(frontier)  # sort for seed reproducibility
        pick = rng.choices(
            candidates,
            weights=[combined_weight(t, selected) for t in candidates],
            k=1,
        )[0]
        selected.add(pick)
        frontier |= set(graph.get(pick, set()))
        frontier -= selected

    return sorted(selected), "connected"


# ------------------------------------------------------------
# CHANGE-4 + V2.1-E: Predicate Generation Aid (E2ETune component 4)
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
    column_usage: dict[str, int] | None = None,
    max_cols: int = 8,
    max_vals: int = 5,
) -> str:
    """
    "table.column (type): v1, v2, ..." lines. Randomising which columns and
    values are shown per query is E2ETune's second diversity lever; v2.1
    additionally weights the column pick by 1/(1+usage) (V2.1-E) so columns
    the workload has not touched yet are shown first -- pushing column
    coverage, a headline notebook metric, instead of re-showing the same
    "obvious" columns.
    """
    usage = column_usage or {}
    lines: list[str] = []
    budget = max_cols
    shuffled_tables = list(tables)
    rng.shuffle(shuffled_tables)

    for table in shuffled_tables:
        if budget <= 0:
            break
        cols = list(columns_by_table.get(table, []))
        if not cols:
            continue
        weights = [1.0 / (1.0 + usage.get(_bare_column_name(c["name"]), 0)) for c in cols]
        picked: list[dict] = []
        pool = list(zip(cols, weights))
        for _ in range(min(3, len(pool))):  # up to 3 columns per table
            total = sum(w for _, w in pool)
            if total <= 0:
                break
            r = rng.random() * total
            acc = 0.0
            for i, (c, w) in enumerate(pool):
                acc += w
                if r <= acc:
                    picked.append(c)
                    pool.pop(i)
                    break
        for col in picked:
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
# shape-spec task injected and CHANGE-5 temperature jitter applied)
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
      1. draw a profile-calibrated shape spec        (V2.1-A)
      2. sample a joinable table subset: mixed
         connected/uniform, coverage- and
         edge-aware                                   (CHANGE-1/2, V2.1-B/D)
      3. fetch DDL context (shared cache, as v1)
      4. build the coverage-aware value aid           (CHANGE-4, V2.1-E)
      5. call the model with jittered temperature     (CHANGE-5)
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

    if variant is not None:
        spec = {"family": variant, "addons": []}
    else:
        spec = sample_shape_spec(rng)
    family = spec["family"]

    # family n_tables override (V2.1-A): "simple" stays at 1-2 tables,
    # deep-join families use the top of the caller's range
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

    # CHANGE-5: jitter around the caller's temperature, clamped to [0.0, 1.0]
    query_temperature = min(1.0, max(0.0, temperature + family["temp_delta"]))

    sql_result = generate_sql(
        client=client,
        schema_context=schema_context,
        task=task,
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
        "prompt_variant": family["name"],
        "shape_addons": [a["name"] for a in spec["addons"]],
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
    Batch generation with CHANGE-6 / V2.1-F novelty control at acceptance
    time: exact duplicates (normalised SQL text, as SQLStorm dedups) are
    always rejected; candidates whose structural skeleton already has
    ``skeleton_cap`` accepted queries, or whose (skeleton, table-set) pair
    was already accepted (the plan-graph-collision proxy), are rejected and
    their slot regenerated within a total attempt budget of
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
    overflow: list[dict] = []  # capped/near-duplicate but textually unique
    attempts = 0
    max_attempts = max(num_queries, math.ceil(num_queries * max_attempt_factor))
    rejected_duplicate = 0
    rejected_skeleton = 0
    rejected_near_dup = 0

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

                if not q.get("sql", ""):
                    continue

                verdict = tracker.try_accept(
                    **accept_args(q),
                    skeleton_cap=skeleton_cap,
                )

                if verdict == "accepted":
                    accepted.append(q)
                elif verdict == "skeleton_capped":
                    rejected_skeleton += 1
                    overflow.append(q)
                elif verdict == "near_duplicate":
                    rejected_near_dup += 1
                    overflow.append(q)
                else:
                    rejected_duplicate += 1

    # graceful degradation: fill any shortfall from capped-but-unique queries
    while len(accepted) < num_queries and overflow:
        q = overflow.pop(0)
        verdict = tracker.try_accept(
            **accept_args(q),
            skeleton_cap=skeleton_cap,
            enforce_caps=False,
        )
        if verdict == "accepted":
            accepted.append(q)

    if rejected_duplicate or rejected_skeleton or rejected_near_dup:
        print(
            f"[novelty control] rejected {rejected_duplicate} duplicates, "
            f"{rejected_skeleton} skeleton-capped, "
            f"{rejected_near_dup} near-duplicates "
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
    additionally records each query's shape family, add-ons, and sampling
    mode, plus the family/add-on/mode mixes -- so the calibration of V2.1-A
    and the effect of CHANGE-1 are auditable per run.
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
    addon_mix = Counter(a for q in queries for a in q.get("shape_addons", []))

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
            "semantic_fields": ["goal"],
        },
        "diversity_mechanisms": {
            "profile_calibrated_shapes": (
                "weighted family + add-on sampling calibrated to the reference "
                "workload's feature means and 13/74/13 complexity mix "
                "(SQLBarber-style distribution targeting on structure)"
            ),
            "mixed_table_sampling": "coverage-weighted connected walk / connectivity-guaranteed uniform subset (E2ETune)",
            "coverage_aware_seeding": "1/(1+usage) table weighting (SQL-Factory Eq. 7, DiGiT)",
            "edge_aware_walk": "1/(1+edge usage) weighting toward under-covered FK edges (DiGiT gap filling)",
            "predicate_value_aid": "sampled live column values, weighted toward unused columns (E2ETune component 4)",
            "temperature_jitter": "per-family delta on base temperature (SQLStorm temp 1.0)",
            "novelty_control": (
                "normalised-SQL dedup + skeleton cap + (skeleton, table-set) "
                "near-duplicate rejection (SQLStorm dedup, SQL-Factory Critical Agent)"
            ),
            "prompt_variant_mix": dict(variant_mix),
            "shape_addon_mix": dict(addon_mix),
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
