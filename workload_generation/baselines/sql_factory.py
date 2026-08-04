"""
SQL-Factory baseline (multi-agent large-scale SQL generation).

    "SQL-Factory: A Multi-Agent Framework for High-Quality and Large-Scale
     SQL Generation."  (PVLDB submission.)

Faithful adaptation of SQL-Factory's three-team, six-agent framework
(paper Section 4) to Trino / Iceberg:

  Generation Team
    * Table Selection Agent -- picks a table subset biased toward *sparsely
      covered* and *structurally complex* tables, using a statistical summary
      of the SQL Pool (per-table query coverage) + schema complexity
      (column count, FK degree). (Eq. 7 in the paper.)
    * Generation Agent      -- a powerful LLM generates a batch of complex,
      diverse queries for the selected tables (their exact prompt: cover as
      many tables as possible; use complex operators / window functions such
      as CASE WHEN, RANK, DENSE_RANK; queries should not be too similar).

  Expansion Team
    * Seed Selection Agent  -- picks high-quality seed queries from the pool.
    * Expansion Agent       -- a lightweight/cheaper model mutates seeds via
      controlled augmentation (add/alter predicates, projections, ordering).

  Management Team
    * Critical Agent        -- executability check (Trino EXPLAIN) + a hybrid
      redundancy score (token 0.6 / AST 0.3 / embedding 0.1) against the pool;
      rejects redundant/invalid queries.
    * Management Agent      -- schedules exploration (Generation) vs
      exploitation (Expansion): starts in exploration, switches to expansion
      after a fixed number of cycles, and switches back if redundancy rises or
      executability drops.  Termination is target-driven, mirroring the
      upstream ``management_node`` (which ends when ``current_sql_num >=
      target_sql_num`` under an effectively unbounded recursion limit rather
      than a fixed round budget).  A progress-based *stall guard* ends a run
      that stops making progress -- a runaway safety valve, not a throughput
      ceiling -- and an optional *saturation stop* (paper Sec 5.2.6) can end
      a run early once the Expansion Team dominates the pool and the pool
      similarity trends upward (semantic saturation).

We approximate the "powerful vs lightweight" model split with reasoning-effort
(``high`` for generation, ``low`` for expansion) on the single deployed model,
and the hybrid similarity's embedding term with a token-shingle Jaccard proxy
when no embedding model is available (token + AST terms are exact).
"""

from __future__ import annotations

import json
import math
import random
import re
from collections import Counter
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

from workload_generation.baselines.common import BaselineContext, write_baseline_workload
from workload_generation.sql_features import query_features, _tokens
from workload_generation.baselines.query_generator import sanitize_sql

try:
    import sqlglot
    _HAVE_SQLGLOT = True
except Exception:
    sqlglot = None
    _HAVE_SQLGLOT = False


BASELINE = "sql_factory"

# --- Generation Agent prompt (paper's exact instruction, adapted) -----------
_GEN_INSTRUCTIONS = (
    "You are a database expert. You are given some tables and their schemas. "
    "Your task is to generate several complex and diverse Trino (Presto) SQL "
    "queries for these tables. Conditions:\n"
    "1. Each query should cover as many of the given tables as possible.\n"
    "2. Prefer complex operators and window functions such as CASE WHEN, RANK, "
    "DENSE_RANK, and others.\n"
    "3. The generated queries should not be too similar to each other.\n"
    "4. Use only the given tables, columns and join keys; use explicit JOIN "
    "syntax; avoid SELECT *. Think carefully before answering.\n"
    "Return strict JSON: {\"queries\": [\"<sql>\", ...]}."
)

_EXP_INSTRUCTIONS = (
    "You are a SQL augmentation assistant. Given a seed Trino SQL query, "
    "produce a *variant* that keeps the same tables but differs meaningfully: "
    "change predicates, add/adjust a GROUP BY / aggregation / ORDER BY, or add "
    "a window function. Keep it valid Trino SQL over the same schema. Return "
    "strict JSON: {\"queries\": [\"<sql>\", ...]}."
)


def _table_complexity(ctx: BaselineContext) -> Dict[str, float]:
    """Schema-level complexity per table: column count + FK degree."""
    graph = ctx.relationship_graph()
    scores = {}
    for t in ctx.schema_tables():
        try:
            ncols = len(ctx.columns_for(t))
        except Exception:
            ncols = 1
        degree = len(graph.get(t, set()))
        scores[t] = 1.0 + ncols + 2.0 * degree
    return scores


def _select_tables(
    ctx: BaselineContext, coverage: Counter, complexity: Dict[str, float],
    *, k: int, rng: random.Random,
) -> List[str]:
    """
    Table Selection Agent (Eq. 7): weight tables by complexity / (1 + coverage)
    so sparsely-covered, structurally-complex tables are preferred, then draw a
    connected-ish subset.
    """
    tables = ctx.schema_tables()
    weights = {t: complexity.get(t, 1.0) / (1.0 + coverage[t]) for t in tables}
    graph = ctx.relationship_graph()

    # weighted pick of a seed, then grow along FK edges preferring high weight
    seed = _weighted_choice(weights, rng)
    selected = [seed]
    sel_set = {seed}
    while len(selected) < k:
        frontier = set()
        for t in selected:
            frontier |= graph.get(t, set())
        frontier -= sel_set
        if not frontier:
            # disconnected: add best remaining by weight
            remaining = [t for t in tables if t not in sel_set]
            if not remaining:
                break
            nxt = max(remaining, key=lambda t: weights[t])
        else:
            nxt = _weighted_choice({t: weights[t] for t in frontier}, rng)
        selected.append(nxt)
        sel_set.add(nxt)
    return sorted(selected)


def _weighted_choice(weights: Dict[str, float], rng: random.Random) -> str:
    items = list(weights.items())
    total = sum(w for _, w in items) or 1.0
    r = rng.random() * total
    upto = 0.0
    for name, w in items:
        upto += w
        if upto >= r:
            return name
    return items[-1][0]


# --- Critical Agent: hybrid similarity (token 0.6 / AST 0.3 / embed 0.1) ----

def _token_sim(a: str, b: str) -> float:
    ta, tb = Counter(_tokens(a)), Counter(_tokens(b))
    if not ta or not tb:
        return 0.0
    inter = sum((ta & tb).values())
    union = sum((ta | tb).values())
    return inter / union if union else 0.0


def _ast_nodes(sql: str) -> Optional[List[str]]:
    if not _HAVE_SQLGLOT:
        return None
    try:
        tree = sqlglot.parse_one(sql, read="trino")
    except Exception:
        return None
    if tree is None:
        return None
    return [type(n).__name__ for n in tree.walk()]


def _ast_sim(a: str, b: str) -> Optional[float]:
    na, nb = _ast_nodes(a), _ast_nodes(b)
    if na is None or nb is None:
        return None
    ca, cb = Counter(na), Counter(nb)
    inter = sum((ca & cb).values())
    denom = max(sum(ca.values()), sum(cb.values())) or 1
    return inter / denom


def _shingle_sim(a: str, b: str, n: int = 3) -> float:
    def sh(s):
        toks = _tokens(s)
        return set(tuple(toks[i:i + n]) for i in range(max(0, len(toks) - n + 1)))
    sa, sb = sh(a), sh(b)
    if not sa or not sb:
        return 0.0
    return len(sa & sb) / len(sa | sb)


def _hybrid_similarity(cand: str, others: List[str]) -> float:
    """Max hybrid similarity of cand vs any query in the pool."""
    if not others:
        return 0.0
    best = 0.0
    for o in others:
        tok = _token_sim(cand, o)
        ast = _ast_sim(cand, o)
        emb = _shingle_sim(cand, o)  # embedding-term proxy
        if ast is None:
            # renormalise token/embed weights when AST unavailable
            sim = (0.6 * tok + 0.1 * emb) / 0.7
        else:
            sim = 0.6 * tok + 0.3 * ast + 0.1 * emb
        best = max(best, sim)
    return best


# --- Generation / Expansion agents ------------------------------------------

def _generation_agent(ctx, tables, n_per_call, seed) -> List[str]:
    rng = random.Random(seed)
    ddl = ctx.ddl_for(tables)
    joins = ctx.foreign_key_text(tables)
    prompt = (
        f"Table Schema:\n{ddl}\n\n"
        f"Foreign Key Dependency:\n{joins}\n\n"
        f"Generate {n_per_call} complex and diverse SQL queries for these tables."
    )
    raw = ctx.responses_text(
        instructions=_GEN_INSTRUCTIONS,
        prompt=prompt,
        reasoning="high",           # "powerful model" for exploration
        temperature=max(ctx.temperature, 0.8),
    )
    return _parse_queries(raw)


def _expansion_agent(ctx, seed_sql, tables, n_per_call, seed) -> List[str]:
    ddl = ctx.ddl_for(tables)
    prompt = (
        f"Schema:\n{ddl}\n\nSeed query:\n{seed_sql}\n\n"
        f"Produce {n_per_call} distinct variants."
    )
    raw = ctx.responses_text(
        instructions=_EXP_INSTRUCTIONS,
        prompt=prompt,
        reasoning="low",            # "lightweight model" for exploitation
        temperature=0.7,
    )
    return _parse_queries(raw)


def _parse_queries(raw: str) -> List[str]:
    try:
        data = json.loads(raw)
        qs = data.get("queries", [])
        return [sanitize_sql(q) for q in qs if q and q.strip()]
    except Exception:
        # fallback: split on blank lines / semicolons
        parts = re.split(r";\s*\n|\n\s*\n", raw)
        return [sanitize_sql(p) for p in parts if "select" in p.lower()]


def _sustained_increase(window: List[float]) -> bool:
    """True if `window` is a non-decreasing, net-rising trend (saturation)."""
    if len(window) < 2:
        return False
    non_decreasing = all(b >= a - 1e-9 for a, b in zip(window, window[1:]))
    return non_decreasing and window[-1] > window[0]


# ---------------------------------------------------------------------------
# Pipeline (Management Team scheduling)
# ---------------------------------------------------------------------------

def generate_workload(
    ctx: BaselineContext,
    *,
    workload_name: str,
    num_queries: int = 100,
    tables_per_selection: int = 4,
    queries_per_call: int = 10,
    similarity_threshold: float = 0.9,
    exploration_cycles: int = 3,
    expansion_cycles: int = 2,
    validation_workers: int = 8,
    max_stall_rounds: int = 6,
    saturation_stop: bool = False,
    saturation_expansion_ratio: float = 0.7,
    saturation_window: int = 4,
    warmup: bool = True,
    random_seed: Optional[int] = None,
    workload_root=None,
) -> Dict[str, Any]:
    """Run the SQL-Factory multi-agent pipeline and write a workload + report.

    Termination mirrors the upstream target-driven stop: the loop runs until
    ``num_queries`` accepted queries are collected, with no fixed round budget.
    ``max_stall_rounds`` is a runaway guard that ends a run only after that many
    *consecutive* rounds accept nothing (scales to any target). When
    ``saturation_stop`` is set, the run also ends early once the Expansion Team
    supplies at least ``saturation_expansion_ratio`` of the pool and the mean
    similarity of newly accepted queries rises across ``saturation_window``
    consecutive productive rounds (paper Sec 5.2.6 semantic saturation).
    """
    started_at = datetime.now(timezone.utc)
    rng = random.Random(random_seed)

    if warmup:
        ctx.warm_up()

    complexity = _table_complexity(ctx)
    coverage: Counter = Counter()

    pool: List[Dict[str, Any]] = []       # accepted queries (the SQL Pool)
    pool_sql: List[str] = []
    schedule_log: List[Dict[str, Any]] = []
    rounds = 0
    total_generated = 0
    rejected_invalid = 0
    rejected_redundant = 0

    state = "GEN"       # Management Agent starts in exploration
    cycles_in_state = 0

    stall = 0                      # consecutive rounds that accepted nothing
    accepted_from_expansion = 0    # for the saturation expansion-ratio signal
    sim_trend: List[float] = []    # mean accepted similarity per productive round
    stop_reason = "target_reached"

    # Target-driven loop (no fixed round budget); guarded against runaway by the
    # stall counter below and, optionally, an early saturation stop.
    while len(pool) < num_queries:
        rounds += 1
        cycles_in_state += 1

        # --- Generation / Expansion produces candidates ---
        if state == "GEN":
            tables = _select_tables(ctx, coverage, complexity,
                                    k=min(tables_per_selection, len(ctx.schema_tables())),
                                    rng=rng)
            try:
                cand_sql = _generation_agent(ctx, tables, queries_per_call,
                                             rng.randint(0, 10**9))
            except Exception as e:
                print(f"[sql_factory] generation agent failed: {type(e).__name__}: {e}")
                cand_sql = []
            cand_tables = tables
        else:  # EXP
            if not pool:
                state, cycles_in_state = "GEN", 0
                continue
            seed = rng.choice(pool)
            cand_tables = seed.get("selected_tables", ctx.schema_tables())
            try:
                cand_sql = _expansion_agent(ctx, seed["sql"], cand_tables,
                                            queries_per_call, rng.randint(0, 10**9))
            except Exception as e:
                print(f"[sql_factory] expansion agent failed: {type(e).__name__}: {e}")
                cand_sql = []

        total_generated += len(cand_sql)
        candidates = [{"sql": s, "selected_tables": cand_tables}
                      for s in cand_sql if s]

        # --- Critical Agent: executability ---
        valid, invalid = ctx.validate_batch(candidates, workers=validation_workers)
        rejected_invalid += len(invalid)

        # --- Critical Agent: hybrid redundancy filter ---
        n_before = len(pool)
        redundant_this_round = 0
        accepted_sims: List[float] = []
        for c in valid:
            sim = _hybrid_similarity(c["sql"], pool_sql)
            # expansion queries are judged more strictly (paper: stricter eval)
            thr = similarity_threshold - (0.05 if state == "EXP" else 0.0)
            if sim >= thr:
                rejected_redundant += 1
                redundant_this_round += 1
                continue
            feats = query_features(c["sql"])
            for t in feats.get("tables", []) or c["selected_tables"]:
                coverage[t] += 1
            pool.append({
                "sql": c["sql"],
                "goal": "SQL-Factory generated query",
                "selected_tables": c["selected_tables"],
                "extra": {"team": "generation" if state == "GEN" else "expansion",
                          "max_pool_similarity": round(sim, 4)},
            })
            pool_sql.append(c["sql"])
            accepted_sims.append(sim)
            if state == "EXP":
                accepted_from_expansion += 1
            if len(pool) >= num_queries:
                break

        accepted_this_round = len(pool) - n_before
        executability = (len(valid) / len(candidates)) if candidates else 0.0
        redundancy_rate = (redundant_this_round / len(valid)) if valid else 0.0

        expansion_ratio = (accepted_from_expansion / len(pool)) if pool else 0.0
        schedule_log.append({
            "round": rounds, "state": state,
            "generated": len(cand_sql), "valid": len(valid),
            "accepted": accepted_this_round,
            "executability": round(executability, 3),
            "redundancy_rate": round(redundancy_rate, 3),
            "expansion_ratio": round(expansion_ratio, 3),
            "stall": stall,
        })

        # --- Management Agent: exploration/exploitation scheduling ---
        if state == "GEN" and cycles_in_state >= exploration_cycles and pool:
            state, cycles_in_state = "EXP", 0
        elif state == "EXP":
            # switch back to exploration if redundancy rises or executability drops
            if redundancy_rate > 0.5 or executability < 0.4 or cycles_in_state >= expansion_cycles:
                state, cycles_in_state = "GEN", 0

        # --- runaway guard: bail after N consecutive unproductive rounds ---
        # (replaces the old fixed `max_rounds` budget; scales to any target).
        if accepted_this_round > 0:
            stall = 0
        else:
            stall += 1
            if stall >= max_stall_rounds:
                stop_reason = "stalled"
                break

        # --- optional saturation early-stop (paper Sec 5.2.6) ---
        # Expansion Team dominates the pool AND the similarity of newly accepted
        # queries is on a sustained upward trend => semantic saturation.
        if saturation_stop and accepted_sims:
            sim_trend.append(sum(accepted_sims) / len(accepted_sims))
            window = sim_trend[-saturation_window:]
            if (expansion_ratio >= saturation_expansion_ratio
                    and len(window) >= saturation_window
                    and _sustained_increase(window)):
                stop_reason = "saturation"
                break

    pool = pool[:num_queries]

    pipeline_report = {
        "method": "SQL-Factory multi-agent generation",
        "teams": {
            "generation": ["Table Selection Agent (coverage+complexity weighted)",
                           "Generation Agent (high-reasoning, complex/diverse)"],
            "expansion": ["Seed Selection Agent", "Expansion Agent (low-reasoning mutation)"],
            "management": ["Critical Agent (EXPLAIN + hybrid similarity)",
                           "Management Agent (exploration/exploitation scheduling)"],
        },
        "hybrid_similarity_weights": {"token": 0.6, "ast": 0.3, "embedding": 0.1,
                                      "ast_available": _HAVE_SQLGLOT,
                                      "embedding_proxy": "token 3-shingle Jaccard"},
        "similarity_threshold": similarity_threshold,
        "scheduling": {"exploration_cycles": exploration_cycles,
                       "expansion_cycles": expansion_cycles,
                       "log": schedule_log},
        "termination": {
            "mode": "target-driven (no fixed round budget)",
            "stop_reason": stop_reason,
            "max_stall_rounds": max_stall_rounds,
            "saturation_stop": saturation_stop,
            "saturation_expansion_ratio": saturation_expansion_ratio,
            "saturation_window": saturation_window,
            "final_expansion_ratio": round(
                (accepted_from_expansion / len(pool)) if pool else 0.0, 3),
        },
        "table_coverage": dict(coverage),
        "counts": {
            "rounds": rounds,
            "total_generated": total_generated,
            "rejected_invalid": rejected_invalid,
            "rejected_redundant": rejected_redundant,
            "accepted": len(pool),
            "target": num_queries,
        },
    }

    return write_baseline_workload(
        baseline=BASELINE,
        workload_name=workload_name,
        queries=pool,
        ctx=ctx,
        started_at=started_at,
        pipeline_report=pipeline_report,
        workload_root=workload_root or _default_root(),
    )


def _default_root():
    from trino_stack.config import WORKLOAD_ROOT
    from pathlib import Path
    return Path(WORKLOAD_ROOT)
