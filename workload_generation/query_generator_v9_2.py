"""
query_generator_v9_2 -- cost-down, diversity-neutral (refines v9_1).

Keeps v9_1's diversity mechanism EXACTLY (the A+C validity-gated lever
curriculum via ``DiversityTrackerV91.sample_hint_set`` + Vendi-aligned reward)
and the v9 token/validity accounting. Changes ONLY how work is scheduled and how
much reasoning each query gets -- both aimed at the 11.7h wall-clock, neither
touching what levers fire or which operators are targeted.

W1  Continuous pipeline parallelism.
    v9/v9_1 generate in WAVES: submit N calls, block until the slowest of the N
    finishes (the ``ThreadPoolExecutor`` context exits), then refill. With
    reasoning=high latency variance (~5-25 min/call) that idles workers on every
    straggler, every wave. v9_2 runs ONE saturating pool: keep
    ``generation_workers`` calls in flight at all times, process each as it
    completes, and refill immediately -- no barriers until the target is met.
    (Pair with a single big ``generate_query_batch`` call from the caller -- see
    Lakehouse.generate_workload -- so there is no outer per-batch barrier and no
    redundant second EXPLAIN pass either.)

W2  Adaptive reasoning effort.
    Output/reasoning tokens were 78% of cost and reasoning=high is the
    multiplier. Diversity comes from the LEVERS, not reasoning depth, so v9_2
    treats the caller's ``reasoning`` as a CEILING and steps it down to
    ``V92_MID_REASONING`` for shallow/small queries (few/no hints, few tables),
    reserving the ceiling for the hard ones (depth >= V92_HIGH_DEPTH or
    n_tables >= V92_HIGH_TABLES) that actually need it to stay valid. The v9_1
    per-depth validity table motivates the split: depth-0 validity ~0.99 (safe
    to downgrade), depth>=2 validity <0.53 (keep high). Per-tier validity and
    tokens are logged so the downgrade can be verified, not assumed.

``feedback_enabled=False`` -> no hints == v6, exactly as v9/v9_1.
"""

from __future__ import annotations

import math
import random
import threading
import time

from collections import Counter
from concurrent.futures import ThreadPoolExecutor, wait, FIRST_COMPLETED

import workload_generation.query_generator_v6 as _v6
import workload_generation.query_generator_v9 as _v9
from workload_generation.query_generator_v9 import (
    _plan_ngrams,
    _levers_of,
    _generate_sql_with_usage,
    load_schema,
    make_openai_client,
    warm_up_model,
    fetch_table_columns,
    fetch_schema_table_columns,
)
from workload_generation.query_generator import (
    register_retry_observer,
    unregister_retry_observer,
    last_retry_count,
)
from workload_generation.query_generator_v9_1 import (
    DiversityTrackerV91,
    V91_MIN_HINTS,
    V91_VALIDITY_TAU,
    V91_CONT_CEILING,
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
    "DiversityTrackerV92",
]

GENERATOR_VERSION = "query_generator_v9_2"

# ---- W2: adaptive reasoning tunables ----
V92_HIGH_DEPTH = 2            # hint_depth >= this keeps the ceiling reasoning
V92_HIGH_TABLES = 6          # n_tables  >= this keeps the ceiling reasoning
V92_MID_REASONING = "medium"  # tier used for shallow/small queries

_REASON_ORDER = {"low": 0, "medium": 1, "high": 2}
_REASON_INV = {0: "low", 1: "medium", 2: "high"}

# ---- W1+: adaptive concurrency (AIMD) tunables ----
# The caller's ``generation_workers`` is the CEILING. The controller ramps the
# in-flight target up while the endpoint is healthy and cuts it hard the moment
# it sees contention (503/504/timeout retries), so throughput self-tunes to what
# the endpoint can actually sustain instead of congestion-collapsing at a fixed
# high worker count.
V92_CONC_MIN = 2                 # never throttle below this many in flight
V92_CONC_START = 8               # initial in-flight target (clamped to ceiling)
V92_CONC_BETA = 0.5              # multiplicative-decrease factor on contention
V92_CONC_PROBE_INTERVAL_S = 12.0  # additive-increase (+1) cadence when healthy
V92_CONC_COOLDOWN_S = 25.0       # after a cut: debounce cuts + pause increases


class ConcurrencyController:
    """AIMD controller for the number of concurrent LLM calls in flight.

    * additive increase: +1 to the in-flight target every
      ``probe_interval_s`` of contention-free operation, up to ``c_max``.
    * multiplicative decrease: on a contention signal (an API retry, surfaced in
      real time via ``query_generator.register_retry_observer``), cut the target
      to ``limit * beta``, then freeze for ``cooldown_s`` so a burst of retries
      from one overload episode causes a single cut, not a collapse.

    Thread-safe; ``on_contention`` is called from worker threads (the retry
    observer) while the scheduler thread calls ``limit`` / ``on_success``.
    """

    def __init__(self, *, c_min, c_max, start,
                 beta=V92_CONC_BETA,
                 probe_interval_s=V92_CONC_PROBE_INTERVAL_S,
                 cooldown_s=V92_CONC_COOLDOWN_S):
        self.c_min = max(1, int(c_min))
        self.c_max = max(self.c_min, int(c_max))
        self.beta = beta
        self.probe_interval_s = probe_interval_s
        self.cooldown_s = cooldown_s
        self._limit = float(min(max(int(start), self.c_min), self.c_max))
        self._lock = threading.Lock()
        now = time.monotonic()
        self._last_change = now
        self._frozen_until = 0.0
        self.increases = 0
        self.decreases = 0
        self.contention_events = 0
        self.min_seen = self._limit
        self.max_seen = self._limit

    def _maybe_increase_locked(self) -> None:
        now = time.monotonic()
        if now < self._frozen_until or self._limit >= self.c_max:
            return
        if now - self._last_change >= self.probe_interval_s:
            self._limit = min(self.c_max, self._limit + 1.0)
            self.increases += 1
            self._last_change = now
            self.max_seen = max(self.max_seen, self._limit)

    def limit(self) -> int:
        with self._lock:
            self._maybe_increase_locked()
            return max(self.c_min, int(round(self._limit)))

    def on_contention(self, exc=None) -> None:
        with self._lock:
            self.contention_events += 1
            now = time.monotonic()
            if now < self._frozen_until:          # debounce: one cut per episode
                return
            new_limit = max(self.c_min, self._limit * self.beta)
            if new_limit < self._limit:
                self._limit = new_limit
                self.decreases += 1
                self.min_seen = min(self.min_seen, self._limit)
            self._frozen_until = now + self.cooldown_s
            self._last_change = now

    def snapshot(self) -> dict:
        with self._lock:
            return {
                "final_limit": max(self.c_min, int(round(self._limit))),
                "ceiling": self.c_max,
                "floor": self.c_min,
                "min_limit_seen": max(self.c_min, int(round(self.min_seen))),
                "max_limit_seen": int(round(self.max_seen)),
                "increases": self.increases,
                "decreases": self.decreases,
                "contention_events": self.contention_events,
            }


def _adaptive_reasoning(ceiling: str, hint_depth: int, n_tables: int) -> str:
    """Step the caller's reasoning ceiling down for shallow/small queries; never
    exceed the ceiling."""
    hard = (hint_depth >= V92_HIGH_DEPTH) or (n_tables >= V92_HIGH_TABLES)
    chosen = ceiling if hard else V92_MID_REASONING
    lvl = min(_REASON_ORDER.get(chosen, 2), _REASON_ORDER.get(ceiling, 2))
    return _REASON_INV[lvl]


# ============================================================
# Tracker: v9_1 policy (A+C) + per-reasoning-tier accounting (W2)
# ============================================================

class DiversityTrackerV92(DiversityTrackerV91):
    """v9_1 tracker (unchanged depth policy + learning) plus per-reasoning-tier
    generation accounting so the W2 downgrade can be measured."""

    def __init__(self):
        super().__init__()
        self.reasoning_fires = Counter()
        self.reasoning_valid = Counter()
        self.reasoning_tok = Counter()

    def record_generation_outcome(self, *, reasoning_effort: str | None = None, **kw) -> None:
        super().record_generation_outcome(**kw)
        if reasoning_effort is not None:
            tt = (kw.get("usage") or (0, 0, 0))[2]
            with self.lock:
                self.reasoning_fires[reasoning_effort] += 1
                if kw.get("valid"):
                    self.reasoning_valid[reasoning_effort] += 1
                self.reasoning_tok[reasoning_effort] += tt

    def generation_accounting_snapshot(self) -> dict:
        snap = super().generation_accounting_snapshot()
        with self.lock:
            per = []
            for tier in ("low", "medium", "high"):
                f = self.reasoning_fires.get(tier, 0)
                if not f:
                    continue
                per.append({
                    "effort": tier,
                    "candidates": f,
                    "valid": self.reasoning_valid.get(tier, 0),
                    "validity_rate": round(self.reasoning_valid.get(tier, 0) / f, 3),
                    "mean_total_tokens": round(self.reasoning_tok.get(tier, 0) / f, 1),
                })
            snap["per_reasoning"] = per
        return snap

    def reset(self):
        super().reset()
        with self.lock:
            self.reasoning_fires.clear()
            self.reasoning_valid.clear()
            self.reasoning_tok.clear()


_DEFAULT_TRACKER_V92 = DiversityTrackerV92()


# ============================================================
# Single-query pipeline (v9 body + W2 adaptive reasoning)
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
    reasoning: str = "high",
    min_tables: int = 2,
    max_tables: int = 8,
    random_seed: int | None = None,
    ddl_cache: dict[str, list[dict]] | None = None,
    ddl_cache_lock=None,
    tracker: DiversityTrackerV92 | None = None,
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
        tracker = _DEFAULT_TRACKER_V92
    if value_cache is None:
        value_cache = _v6._VALUE_CACHE
    if value_cache_lock is None:
        value_cache_lock = _v6._VALUE_CACHE_LOCK

    rng = random.Random(random_seed)

    if variant is not None:
        spec = {"family": variant, "addons": [], "plan_shape": None}
    else:
        spec = _v6.sample_shape_spec(rng)
    family = spec["family"]

    # v9_1's A+C validity-gated lever set (via the tracker, unchanged).
    hint_ids: list[str] = []
    if variant is None:
        for h in tracker.sample_hint_set(rng, family_name=family["name"]):
            spec["addons"].append({"name": h["lever_id"], "line": h["line"]})
            hint_ids.append(h["lever_id"])
    hint_depth = len(hint_ids)

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

    # W2: reasoning tier scaled to this query's difficulty (caller's = ceiling).
    reasoning_effort = _adaptive_reasoning(reasoning, hint_depth, len(selected_tables))

    sql_result = _generate_sql_with_usage(
        client=client, schema_context=schema_context, task=task,
        model_name=model_name, temperature=query_temperature, reasoning=reasoning_effort,
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
        "reasoning_effort": reasoning_effort,
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


# ============================================================
# Batch generation (W1: single continuous saturating pool)
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
    reasoning="high",
    min_tables: int = 2,
    max_tables: int = 8,
    random_seed: int | None = None,
    ddl_cache: dict[str, list[dict]] | None = None,
    ddl_cache_lock=None,
    generation_workers: int = 4,
    tracker: DiversityTrackerV92 | None = None,
    connected_fraction: float = 0.5,
    skeleton_cap: int = 12,
    plan_signature_cap: int = 3,
    max_attempt_factor: float = 4.0,
    progress_cb=None,
) -> list[dict]:
    rng = random.Random(random_seed)

    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()
    if tracker is None:
        tracker = _DEFAULT_TRACKER_V92

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
        # Contention signal: retries this LLM call incurred (thread-local, set by
        # call_with_retry on this worker thread during generate_query).
        q["contention_retries"] = last_retry_count()
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

        tracker.record_generation_outcome(
            hint_depth=q.get("hint_depth", 0),
            valid=bool(q.get("plan_valid")),
            usage=q.get("usage", (0, 0, 0)),
            sql=q.get("sql"),
            error=None if q.get("plan_valid") else "plan did not compile (EXPLAIN failed)",
            reasoning_effort=q.get("reasoning_effort"),
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

    def _process(q: dict) -> None:
        nonlocal rejected_invalid, rejected_duplicate, rejected_plan_dup
        nonlocal rejected_plan_cap, rejected_skeleton, rejected_near_dup
        if not q.get("sql", ""):
            return
        if not q.get("plan_valid"):
            rejected_invalid += 1
            return
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

    # ---- W1+: one saturating pool with an AIMD in-flight target ----
    # generation_workers is the CEILING; the controller ramps up while the
    # endpoint is healthy and cuts hard on contention (retry observer), so we
    # find the sustainable concurrency instead of congestion-collapsing at a
    # fixed high worker count.
    controller = ConcurrencyController(
        c_min=V92_CONC_MIN,
        c_max=max(1, generation_workers),
        start=min(max(1, generation_workers), V92_CONC_START),
    )
    register_retry_observer(controller.on_contention)

    executor = ThreadPoolExecutor(max_workers=max(1, generation_workers))
    inflight: set = set()

    def _submit() -> bool:
        nonlocal attempts
        if attempts >= max_attempts:
            return False
        inflight.add(executor.submit(worker, rng.randint(0, 10**9)))
        attempts += 1
        return True

    def _refill() -> None:
        while (len(inflight) < controller.limit()
               and len(accepted) < num_queries
               and attempts < max_attempts):
            if not _submit():
                break

    def _emit(event: str) -> None:
        if progress_cb is None:
            return
        try:
            progress_cb({
                "event": event,
                "accepted": len(accepted),
                "target": num_queries,
                "attempts": attempts,
                "max_attempts": max_attempts,
                "inflight": len(inflight),
                "concurrency_limit": controller.limit(),
                "rejected_invalid": rejected_invalid,
                "contention_events": controller.contention_events,
            })
        except Exception:
            pass

    try:
        _refill()                                     # prime up to the initial limit
        _emit("start")
        while inflight and len(accepted) < num_queries:
            # timeout wakes the loop under stalls so the controller can probe
            # upward and the progress bar keeps refreshing even mid-straggler.
            done, _pending = wait(inflight, timeout=2.0, return_when=FIRST_COMPLETED)
            for fut in done:
                inflight.discard(fut)
                try:
                    _process(fut.result())
                except Exception as e:
                    controller.on_contention()        # a bubbled failure == contention
                    print(f"[generation failed] {type(e).__name__}: {e}")
            _refill()
            _emit("progress" if done else "tick")
    finally:
        unregister_retry_observer(controller.on_contention)
        # target met (or budget exhausted): stop scheduling; let the running
        # calls finish in the background (bounded tail, no barrier).
        try:
            executor.shutdown(wait=False, cancel_futures=True)   # py>=3.9
        except TypeError:
            executor.shutdown(wait=False)

    try:
        tracker._concurrency_snapshot = controller.snapshot()
    except Exception:
        pass
    _emit("done")

    # relaxed second pass over cap-rejected candidates (unchanged from v9)
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
# Workload writer -- v9's writer, retagged v9_2.
# ============================================================

def write_workload_directory(**kwargs):
    return _v9.write_workload_directory(
        generator_version=GENERATOR_VERSION,
        feedback_overrides={
            "mechanism": (
                "v9_1 A+C validity-gated lever curriculum (unchanged) + "
                "W1+ adaptive-concurrency continuous pool (AIMD) + W2 adaptive reasoning"
            ),
            "depth_policy": (
                f"forced >= {V91_MIN_HINTS} hint(s); deeper continue while "
                f"Thompson(validity@k+1) > tau={V91_VALIDITY_TAU} (ceiling "
                f"{V91_CONT_CEILING})"
            ),
            "min_hints_forced": V91_MIN_HINTS,
            "validity_tau": V91_VALIDITY_TAU,
            "continuation_ceiling": V91_CONT_CEILING,
            "adaptive_reasoning": (
                f"ceiling for hint_depth>={V92_HIGH_DEPTH} or "
                f"n_tables>={V92_HIGH_TABLES}, else {V92_MID_REASONING}"
            ),
        },
        **kwargs,
    )
