"""
query_generator_v9 -- validity-gated curriculum of levers (forks v8).

Why fork v8
-----------
v8 beat every prior version on plan-graph Vendi (114 vs v6_exotic 72) but its
DEPTH mechanism is blind: the number of stacked deficit hints per query is
``n_ops = 1 + _hint_aggression`` (+ a pairing coin), and ``_hint_aggression``
ratchets up on a *discovery-saturation* signal that is guaranteed to fire on any
long run (the frozen ``discovery[:100]`` baseline). In the v8 1000-query run it
pinned at the maximum (3) and we observed an early spike in invalid queries --
the generator was reaching for hard, deep queries far sooner than the model
could reliably satisfy, with NO validity feedback braking it.

v9 keeps v8's two working pieces untouched:
  * the operator-space grounding + named-operator deficit hints (F-0/F-1), and
  * the softmax-over-deficit SELECTION of *which* lever to add,
and replaces ONLY the DEPTH decision (how many levers) with a validity-gated
curriculum.

New machinery
-------------
  G-1  Sequential hazard depth. A query's lever set is built one lever at a
       time. After committing k levers, we CONTINUE to k+1 with a probability
       drawn from a per-depth validity posterior (Thompson sampling), modulated
       by a diversity brake. This gives an unbounded-in-principle but
       discrete depth distribution with no continuous parameter -- one
       continuation gate per depth, instantiated lazily. Hard-capped at
       ``V9_MAX_DEPTH`` levers.

  G-2  Per-depth validity Beta gates. For every candidate the LLM produces
       (valid OR invalid), we update ``Beta(alpha_d, beta_d)`` for the depth d
       it was generated at. The gate deciding k -> k+1 Thompson-samples the
       belief about depth k+1, so depth only opens up as evidence accrues that
       the model stays valid there. Priors are deeper-is-harder:
       ``Beta(1, 1 + PESSIMISM*(d-1))`` -> gate 0->1 starts at ~0.5 (the "X").

  G-3  Diversity brake (secondary signal). A per-depth EWMA of new-3-gram yield;
       starts neutral (1.0) so validity drives early exploration, and only
       *reduces* the continuation probability once a depth proves unproductive
       (floor ``V9_DIV_FLOOR``). Honours "more levers => more diversity
       opportunity" as a prior, corrected by evidence.

  G-4  Generation accounting. Token usage (input/output/total) and validity are
       captured for EVERY candidate -- accepted and failed -- and aggregated
       per-depth and per-workload. This finally makes the failure spike and the
       generation cost measurable (v8 logged neither).

``feedback_enabled=False`` -> no hints, no gate effect on generation == v6.
"""

from __future__ import annotations

import json
import math
import random
import threading

from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed

import workload_generation.query_generator_v6 as _v6
from workload_generation.query_generator_v6 import (
    load_schema,
    make_openai_client,
    warm_up_model,
    fetch_table_columns,
    fetch_schema_table_columns,
)
from workload_generation import utils as _opspace

# Token-capturing SQL call re-implements v2's generate_sql body (which discards
# the raw response, and so the usage block) -- all shared pieces imported.
from workload_generation.query_generator_v2 import (
    PROMPT_TEMPLATE,
    INSTRUCTIONS_TEMPLATE,
    _OUTPUT_SCHEMA,
    USE_RESPONSES_STREAMING,
    MODEL_NAME,
    call_with_retry,
    normalise_sql_result,
)

# Reuse v8's tracker for its v3+operator state; v9 only swaps the depth policy.
from workload_generation.query_generator_v8 import DiversityTrackerV8, _plan_ngrams

__all__ = [
    "load_schema",
    "make_openai_client",
    "warm_up_model",
    "generate_query",
    "generate_query_batch",
    "write_workload_directory",
    "fetch_table_columns",
    "fetch_schema_table_columns",
    "DiversityTrackerV9",
]

GENERATOR_VERSION = "query_generator_v9"

# ---- tunables (ablation knobs, NOT statistical thresholds) ----
V9_MAX_DEPTH = 5              # G-1: hard cap on stacked deficit hints per query
V9_DEPTH_PRIOR_PESSIMISM = 1.0  # G-2: deeper priors Beta(1, 1+PESSIMISM*(d-1))
V9_DIV_FLOOR = 0.4           # G-3: floor on the diversity brake multiplier
V9_DIV_EWMA_ALPHA = 0.2      # G-3: EWMA weight for per-depth new-3-gram yield
V9_SOFTMAX_TEMP = 0.5        # selection temperature over deficit scores (from v8)
V9_CONDITIONAL_WEIGHT = 0.6  # relative weight of reliability=="conditional" levers
V9_ATTACH_SNIPPET = False    # attach lever example_snippet inline (see v8 note)
V9_MAX_FAILED_STORE = 500    # G-4: cap on stored failed-query records in report


# ============================================================
# G-4: token-capturing SQL call (v2 body + usage extraction)
# ============================================================

def _usage_tuple(resp) -> tuple[int, int, int]:
    """(input, output, total) tokens from a Responses-API result, defensively."""
    u = getattr(resp, "usage", None)
    if u is None:
        return (0, 0, 0)
    ti = getattr(u, "input_tokens", None) or getattr(u, "prompt_tokens", 0) or 0
    to = getattr(u, "output_tokens", None) or getattr(u, "completion_tokens", 0) or 0
    tt = getattr(u, "total_tokens", None) or (ti + to)
    return (int(ti), int(to), int(tt))


def _generate_sql_with_usage(
    client,
    schema_context: str,
    *,
    task: str,
    reasoning: str = "medium",
    model_name: str = MODEL_NAME,
    temperature: float = 0.6,
) -> dict:
    """Same call as v2.generate_sql, but returns the token usage alongside the
    normalised result under the reserved ``usage`` key."""
    def _call():
        kwargs = dict(
            model=model_name,
            instructions=INSTRUCTIONS_TEMPLATE,
            input=PROMPT_TEMPLATE.format(schema_context=schema_context, task=task),
            reasoning={"effort": reasoning},
            text={"format": _OUTPUT_SCHEMA},
            temperature=temperature,
            store=False,
        )
        if USE_RESPONSES_STREAMING:
            with client.responses.stream(**kwargs) as stream:
                return stream.get_final_response()
        return client.responses.create(**kwargs)

    result = call_with_retry(_call)
    data = normalise_sql_result(json.loads(result.output_text))
    data["usage"] = _usage_tuple(result)
    return data


# ============================================================
# Tracker: v8 operator state + G-1..G-4 depth curriculum & accounting
# ============================================================

class DiversityTrackerV9(DiversityTrackerV8):
    """v8 tracker (operator-space grounding + softmax selection) with v8's blind
    ``_hint_aggression`` depth policy replaced by a validity-gated curriculum,
    plus token/validity accounting over every candidate.
    """

    def __init__(self):
        super().__init__()
        # G-2: per-depth validity Beta posteriors. Index d = #levers on a query.
        n = V9_MAX_DEPTH + 1
        self.depth_alpha = [1.0] * n
        self.depth_beta = [
            1.0 + V9_DEPTH_PRIOR_PESSIMISM * max(0, d - 1) for d in range(n)
        ]
        # G-3: per-depth EWMA of new-3-gram yield (diversity brake input).
        self.depth_new_ewma = [0.0] * n
        self.depth_new_seen = [False] * n
        # G-4: generation accounting (all candidates, valid + invalid).
        self.gen_candidates = 0
        self.gen_valid = 0
        self.gen_invalid = 0
        self.gen_tok_in = 0
        self.gen_tok_out = 0
        self.gen_tok_total = 0
        self.depth_fires = Counter()      # candidates generated at depth d
        self.depth_valid = Counter()      # of those, valid
        self.depth_tok_total = Counter()  # summed total tokens at depth d
        self.failed_records: list[dict] = []

    # ---- G-1: sequential validity-gated lever set ----
    def sample_hint_set(self, rng: random.Random, *, family_name: str) -> list[dict]:
        """Build a lever set one lever at a time. After k committed levers,
        continue to k+1 with prob = Thompson(validity@k+1) * diversity_brake(k+1).
        Returns ``[{"lever_id", "line"}, ...]``."""
        if not self.feedback_enabled or not self._hint_candidates:
            return []
        if family_name == "simple":                  # keep the simple family simple
            return []

        with self.lock:
            usage = dict(self.operator_usage)
            alpha = list(self.depth_alpha)
            beta = list(self.depth_beta)
            div = [self._diversity_brake_locked(d) for d in range(len(alpha))]

        # Static deficit scores for this query (need * reliability). Selection is
        # softmax over these (L1: sample, don't argmax) -- unchanged from v8.
        scored = []
        for lv in self._hint_candidates:
            need = 1.0 / (1.0 + usage.get(lv.target_operator, 0))
            rel = 1.0 if lv.reliability == "guaranteed" else V9_CONDITIONAL_WEIGHT
            scored.append((lv, need * rel))

        chosen, used_ops = [], set()
        k = 0
        while k < V9_MAX_DEPTH:
            nxt = k + 1
            theta = rng.betavariate(alpha[nxt], beta[nxt])   # G-2 Thompson gate
            p_cont = theta * div[nxt]                         # G-3 diversity brake
            if rng.random() >= p_cont:
                break
            pool = [(lv, s) for (lv, s) in scored if lv.target_operator not in used_ops]
            if not pool:
                break
            weights = [math.exp(s / V9_SOFTMAX_TEMP) for _lv, s in pool]
            lv = rng.choices([lv for lv, _s in pool], weights=weights, k=1)[0]
            chosen.append(lv)
            used_ops.add(lv.target_operator)
            k += 1

        return [{"lever_id": lv.lever_id, "line": self._hint_line(lv)} for lv in chosen]

    def _diversity_brake_locked(self, d: int) -> float:
        """Multiplier in [V9_DIV_FLOOR, 1.0]. 1.0 until depth d has produced
        evidence; then scales with d's new-3-gram yield relative to the most
        productive depth seen (so an unproductive depth is braked, not starved)."""
        if d >= len(self.depth_new_ewma) or not self.depth_new_seen[d]:
            return 1.0
        seen = [self.depth_new_ewma[i] for i in range(len(self.depth_new_ewma))
                if self.depth_new_seen[i]]
        top = max(seen) if seen else 0.0
        if top <= 0:
            return 1.0
        norm = min(1.0, self.depth_new_ewma[d] / top)
        return V9_DIV_FLOOR + (1.0 - V9_DIV_FLOOR) * norm

    def _hint_line(self, lv) -> str:
        line = lv.prompt_hint
        if V9_ATTACH_SNIPPET and lv.reliability == "conditional":
            line = f"{line} For example, in the style of: {lv.example_snippet}"
        return line

    # ---- G-2/G-4: learn from EVERY candidate the model produced ----
    def record_generation_outcome(
        self, *, hint_depth: int, valid: bool,
        usage: tuple[int, int, int] = (0, 0, 0),
        sql: str | None = None, error=None,
    ) -> None:
        d = max(0, min(int(hint_depth), V9_MAX_DEPTH))
        ti, to, tt = usage
        with self.lock:
            self.gen_candidates += 1
            self.gen_tok_in += ti
            self.gen_tok_out += to
            self.gen_tok_total += tt
            self.depth_fires[d] += 1
            self.depth_tok_total[d] += tt
            if valid:
                self.gen_valid += 1
                self.depth_valid[d] += 1
                self.depth_alpha[d] += 1.0            # G-2 posterior update
            else:
                self.gen_invalid += 1
                self.depth_beta[d] += 1.0
                if len(self.failed_records) < V9_MAX_FAILED_STORE:
                    self.failed_records.append({
                        "hint_depth": d,
                        "tokens": {"input": ti, "output": to, "total": tt},
                        "error": str(error)[:500] if error is not None else None,
                        "sql": (sql or "")[:4000],
                    })

    # ---- accept-time bookkeeping: v8's, plus G-3 per-depth novelty EWMA ----
    def try_accept(self, **kwargs) -> str:
        hint_depth = kwargs.pop("hint_depth", 0)
        plan_ngrams = kwargs.get("plan_ngrams")           # peek (v8 consumes it)
        # measure novelty BEFORE v8 folds these grams into ngram_usage
        with self.lock:
            grams = plan_ngrams or Counter()
            new = sum(1 for g in grams if self.ngram_usage.get(g, 0) == 0)
        verdict = super().try_accept(**kwargs)
        if verdict == "accepted":
            d = max(0, min(int(hint_depth), V9_MAX_DEPTH))
            with self.lock:
                a = V9_DIV_EWMA_ALPHA
                prev = self.depth_new_ewma[d]
                self.depth_new_ewma[d] = (1 - a) * prev + a * float(new) \
                    if self.depth_new_seen[d] else float(new)
                self.depth_new_seen[d] = True
        return verdict

    # ---- reporting ----
    def generation_accounting_snapshot(self) -> dict:
        with self.lock:
            per_depth = []
            for d in range(V9_MAX_DEPTH + 1):
                fires = self.depth_fires.get(d, 0)
                valid = self.depth_valid.get(d, 0)
                a, b = self.depth_alpha[d], self.depth_beta[d]
                per_depth.append({
                    "depth": d,
                    "candidates": fires,
                    "valid": valid,
                    "invalid": fires - valid,
                    "validity_rate": round(valid / fires, 3) if fires else None,
                    "posterior_validity_mean": round(a / (a + b), 3),
                    "mean_total_tokens": (
                        round(self.depth_tok_total.get(d, 0) / fires, 1) if fires else None
                    ),
                })
            cands = self.gen_candidates
            return {
                "total_candidates": cands,
                "valid": self.gen_valid,
                "invalid": self.gen_invalid,
                "validity_rate": round(self.gen_valid / cands, 4) if cands else None,
                "tokens": {
                    "input": self.gen_tok_in,
                    "output": self.gen_tok_out,
                    "total": self.gen_tok_total,
                },
                "tokens_per_candidate": (
                    round(self.gen_tok_total / cands, 1) if cands else None
                ),
                "tokens_per_valid": (
                    round(self.gen_tok_total / self.gen_valid, 1) if self.gen_valid else None
                ),
                "max_depth": V9_MAX_DEPTH,
                "per_depth": per_depth,
                "num_failed_records": len(self.failed_records),
            }

    def failed_query_records(self) -> list[dict]:
        with self.lock:
            return list(self.failed_records)

    def reset(self):
        super().reset()
        with self.lock:
            n = V9_MAX_DEPTH + 1
            self.depth_alpha = [1.0] * n
            self.depth_beta = [
                1.0 + V9_DEPTH_PRIOR_PESSIMISM * max(0, d - 1) for d in range(n)
            ]
            self.depth_new_ewma = [0.0] * n
            self.depth_new_seen = [False] * n
            self.gen_candidates = self.gen_valid = self.gen_invalid = 0
            self.gen_tok_in = self.gen_tok_out = self.gen_tok_total = 0
            self.depth_fires.clear()
            self.depth_valid.clear()
            self.depth_tok_total.clear()
            self.failed_records.clear()


_DEFAULT_TRACKER_V9 = DiversityTrackerV9()


# ============================================================
# Single-query pipeline (v6 body + G-1 hint set + G-4 usage capture)
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
    tracker: DiversityTrackerV9 | None = None,
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
        tracker = _DEFAULT_TRACKER_V9
    if value_cache is None:
        value_cache = _v6._VALUE_CACHE
    if value_cache_lock is None:
        value_cache_lock = _v6._VALUE_CACHE_LOCK

    rng = random.Random(random_seed)

    # v6's shape draw is UNCHANGED.
    if variant is not None:
        spec = {"family": variant, "addons": [], "plan_shape": None}
    else:
        spec = _v6.sample_shape_spec(rng)
    family = spec["family"]

    # G-1: validity-gated lever set as synthetic task-line add-ons.
    hint_ids: list[str] = []
    if variant is None:
        for h in tracker.sample_hint_set(rng, family_name=family["name"]):
            spec["addons"].append({"name": h["lever_id"], "line": h["line"]})
            hint_ids.append(h["lever_id"])
    hint_depth = len(hint_ids)

    # Plan size: v6's, unchanged.
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

    base_temp = max(temperature, _v6.V6_TEMPERATURE_FLOOR)
    query_temperature = min(1.0, max(0.0, base_temp + family["temp_delta"]))

    sql_result = _generate_sql_with_usage(
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
        "usage": sql_result.get("usage", (0, 0, 0)),
        "hint_depth": hint_depth,
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
# Batch generation (v6 loop + G-2/G-4 outcome recording)
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
    tracker: DiversityTrackerV9 | None = None,
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
        tracker = _DEFAULT_TRACKER_V9

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

        # G-2/G-4: learn from EVERY candidate -- valid or invalid. This is the
        # LLM-validity signal that gates depth and the whole cost picture; it is
        # the piece v8 never recorded.
        tracker.record_generation_outcome(
            hint_depth=q.get("hint_depth", 0),
            valid=bool(q.get("plan_valid")),
            usage=q.get("usage", (0, 0, 0)),
            sql=q.get("sql"),
            error=None if q.get("plan_valid") else "plan did not compile (EXPLAIN failed)",
        )
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
            "hint_depth": q.get("hint_depth", 0),
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
# Workload writer -- v6's, retagged v9, enriched with per-query usage +
# generation accounting (incl. failed queries).
# ============================================================

def write_workload_directory(
    *,
    tracker: DiversityTrackerV9 | None = None,
    queries: list[dict],
    extra_report_fields: dict | None = None,
    generator_version: str = GENERATOR_VERSION,
    feedback_overrides: dict | None = None,
    **kwargs,
):
    extra = dict(extra_report_fields or {})
    extra["generator"] = generator_version

    fb = {
        "mechanism": "validity-gated lever curriculum (Thompson per-depth gates) + Vendi-aligned 3-gram reward",
        "depth_policy": "sequential hazard: continue k->k+1 with Thompson(validity@k+1) * diversity_brake",
        "max_depth": V9_MAX_DEPTH,
        "depth_prior_pessimism": V9_DEPTH_PRIOR_PESSIMISM,
        "diversity_floor": V9_DIV_FLOOR,
        "softmax_temp": V9_SOFTMAX_TEMP,
        "ceiling_source": "workload_generation.resources (operators_ground_truth.csv + lever_operator_map.csv)",
    }
    if feedback_overrides:
        fb.update(feedback_overrides)
    if tracker is not None:
        fb.update(tracker.plan_feedback_snapshot())
        fb["feedback_enabled"] = tracker.feedback_enabled
        extra.setdefault("generation_accounting", tracker.generation_accounting_snapshot())
        extra.setdefault("failed_queries", tracker.failed_query_records())
    extra.setdefault("plan_feedback", fb)

    report = _v6.write_workload_directory(queries=queries, extra_report_fields=extra, **kwargs)

    # v6's writer emits a fixed per-query key set; splice in v9's per-query
    # validity + token usage (queries are written in list order and stamped with
    # query_name in place, so index alignment is exact).
    if report.get("queries"):
        for rec, q in zip(report["queries"], queries):
            ti, to, tt = q.get("usage", (0, 0, 0))
            rec["hint_depth"] = q.get("hint_depth", 0)
            rec["deficit_hints"] = q.get("deficit_hints", [])
            rec["plan_valid"] = bool(q.get("plan_valid", True))
            rec["tokens"] = {"input": ti, "output": to, "total": tt}
        # rewrite the file with the enriched query records
        from pathlib import Path as _Path
        _Path(report["workload_dir"], "generation_report.json").write_text(
            json.dumps(report, indent=2, default=str), encoding="utf-8"
        )

    return report
