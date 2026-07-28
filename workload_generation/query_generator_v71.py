"""
query_generator_v71 -- online additive plan-feedback generator (forks v6).

Why v7.1 exists
---------------
v7 measured a plan-space coverage gap that does not exist at scale: on a 1000-
query TPC-DS run v6 already saturates the operator vocabulary (33 types, plan
uniqueness 1.0). v7's *multiplicative* reweighting (weight = base * rarity) could
drive a lever's weight to ~0, so once a rare operator was covered its lever was
switched off; the shape distribution collapsed onto default+chain, the rich
add-ons (set_op, grouping_sets) were annihilated, plans shrank, and plan-graph
Vendi FELL 71.6 -> 54.1. v7 also depended on an offline calibration whose 100-
plan, 1-SE affinity map was badly overfit (every lever "learned" InnerJoin /
Aggregate), so the boost went to diversity-neutral levers (limit, order_by).

v7.1 keeps the idea -- close the loop on the compiled plan -- but makes it
*safe* and *calibration-free*:

  1. ADDITIVE FLOOR, never annihilate.  weight = base * (1 + strength * rarity),
     rarity in [0, 1]. Add-ons are independent draws, so their probability has a
     strict floor (set_op stays >= its base p). Plan-shapes are a weighted
     choice, so a boosted shape only *halves* others' share at most -- bounded
     suppression, never zero. strength = 0 reproduces v6 exactly.

  2. NO CALIBRATION, NO idf.  The coverage term 1/(1+usage) already discounts
     ubiquitous operators (huge usage -> ~0 need), so the offline idf table is
     redundant and removed. There is no warm-up / freeze / bootstrap.

  3. ONLINE SELF-ATTRIBUTION replaces the frozen affinity map.  Each accepted
     plan's physical operators are attributed to the levers that were active
     when it was generated (running co-occurrence). rarity(lever) is the MAX
     over that lever's operators of P(op|lever) * 1/(1+usage(op)) -- "this lever
     reliably yields an operator the workload is still missing". MAX (not v7's
     mean over a stopword-padded list) means a lever is credited for its single
     most-under-covered operator and never diluted by InnerJoin/Aggregate.

Cold start is safe: with no co-occurrence yet, rarity = 0 -> weight = base ->
pure v6, until evidence accrues. Everything else (plan-graph dedup + family cap,
attempt budget, report layout) is v6 unchanged.
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
    PROMPT_VARIANTS,
    PLAN_SHAPES,
    V6_ADDON_SPECS,
    DiversityTrackerV3,
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
    "DiversityTrackerV71",
    "V71_FEEDBACK_STRENGTH",
]

GENERATOR_VERSION = "query_generator_v71"

# Additive strength. weight = base * (1 + strength * rarity), rarity in [0,1].
# 0.0 == v6 exactly; 1.0 lets a lever at most double its base weight.
V71_FEEDBACK_STRENGTH = 1.0


# ============================================================
# Tracker: v3 tracker + online operator coverage + lever co-occurrence
# ============================================================

class DiversityTrackerV71(DiversityTrackerV3):
    """v3 tracker plus online plan-space feedback state:

      * ``operator_usage``  -- document-frequency (presence-per-plan) of each
        physical operator across the accepted workload. Drives the coverage
        term 1/(1+usage); ubiquitous operators self-discount here.
      * ``lever_op_cooc`` / ``lever_draws`` -- online attribution: how often
        each lever, when active, co-occurred with each operator. Replaces v7's
        frozen affinity map; no calibration needed.

    ``feedback_enabled`` toggles steering off (== v6) without a code change.
    """

    def __init__(self):
        super().__init__()
        self.operator_usage: Counter = Counter()
        self.lever_draws: Counter = Counter()
        self.lever_op_cooc: dict[str, Counter] = defaultdict(Counter)
        self.plans_seen: int = 0
        self.feedback_enabled: bool = True

    def try_accept(self, **kwargs) -> str:
        """v3 accept, plus record operator coverage and lever->operator
        co-occurrence on acceptance. ``levers`` (the directives active for this
        candidate) is popped here; ``plan_family`` (coarse operator multiset) is
        already a v3 kwarg and stays for super()."""
        levers = kwargs.pop("levers", ()) or ()
        plan_family = kwargs.get("plan_family")
        verdict = super().try_accept(**kwargs)
        if verdict == "accepted" and plan_family is not None:
            ops = [op for op, _count in plan_family]
            with self.lock:
                self.plans_seen += 1
                for op in ops:
                    self.operator_usage[op] += 1
                for L in levers:
                    self.lever_draws[L] += 1
                    cooc = self.lever_op_cooc[L]
                    for op in ops:
                        cooc[op] += 1
        return verdict

    def lever_rarity(self, lever_name: str) -> float:
        """max over the lever's attributed operators of
        P(op|lever) * 1/(1+usage(op)), in [0, 1]. MAX credits the lever for its
        single most-under-covered operator; coverage handles ubiquity, so no idf
        is needed. 0 when feedback is off or the lever has no evidence yet."""
        if not self.feedback_enabled:
            return 0.0
        with self.lock:
            draws = self.lever_draws.get(lever_name, 0)
            cooc = self.lever_op_cooc.get(lever_name)
            if draws == 0 or not cooc:
                return 0.0
            best = 0.0
            for op, c in cooc.items():
                rate = c / draws                                  # P(op|lever)
                need = 1.0 / (1.0 + self.operator_usage.get(op, 0))
                val = rate * need
                if val > best:
                    best = val
            return best

    def plan_feedback_snapshot(self) -> dict:
        with self.lock:
            return {
                "plans_seen": self.plans_seen,
                "operator_usage": dict(self.operator_usage),
                "lever_draws": dict(self.lever_draws),
            }

    def reset(self):
        super().reset()
        with self.lock:
            self.operator_usage.clear()
            self.lever_draws.clear()
            self.lever_op_cooc.clear()
            self.plans_seen = 0


_DEFAULT_TRACKER_V71 = DiversityTrackerV71()


# ============================================================
# Additive-floor shape draw
# ============================================================

def _boost(tracker: DiversityTrackerV71 | None, name: str) -> float:
    """Additive multiplier 1 + strength*rarity, in [1, 1+strength]. Always >= 1,
    so a lever's weight never drops below its v6 base."""
    if tracker is None or not getattr(tracker, "feedback_enabled", False):
        return 1.0
    return 1.0 + V71_FEEDBACK_STRENGTH * tracker.lever_rarity(name)


def sample_shape_spec(rng: random.Random, tracker: DiversityTrackerV71 | None = None) -> dict:
    """v6's draw with an additive-floor boost applied to add-on probabilities and
    plan-shape weights. Never suppresses below base (add-ons: strict floor;
    plan-shapes: bounded, at most halves a share)."""
    weights = [v["weight"] for v in PROMPT_VARIANTS]
    family = rng.choices(PROMPT_VARIANTS, weights=weights, k=1)[0]

    addons = []
    for spec in V6_ADDON_SPECS:
        if family["name"] == "simple" and not spec["simple_ok"]:
            continue
        if family["name"] in spec.get("skip_families", ()):
            continue
        p = min(1.0, spec["p"] * _boost(tracker, spec["name"]))
        if rng.random() < p:
            addons.append(spec)

    plan_shape = None
    if family.get("join_all"):
        w = [p["weight"] * _boost(tracker, p["name"]) for p in PLAN_SHAPES]
        plan_shape = rng.choices(PLAN_SHAPES, weights=w, k=1)[0]

    return {"family": family, "addons": addons, "plan_shape": plan_shape}


# ============================================================
# Single-query pipeline (v6 body; feedback-aware shape draw only)
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
    tracker: DiversityTrackerV71 | None = None,
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
        tracker = _DEFAULT_TRACKER_V71
    if value_cache is None:
        value_cache = _v6._VALUE_CACHE
    if value_cache_lock is None:
        value_cache_lock = _v6._VALUE_CACHE_LOCK

    rng = random.Random(random_seed)

    if variant is not None:
        spec = {"family": variant, "addons": [], "plan_shape": None}
    else:
        spec = sample_shape_spec(rng, tracker=tracker)   # additive-floor feedback
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
        "sampling_mode": sampling_mode,
        "plan_shape": plan_shape["name"] if plan_shape else "none",
    }


def _levers_of(q: dict) -> set[str]:
    """The directives active for a candidate (add-ons + plan shape), used for
    online attribution."""
    levers = set(q.get("shape_addons", []))
    ps = q.get("plan_shape")
    if ps and ps != "none":
        levers.add(ps)
    return levers


# ============================================================
# Batch generation (v6 loop; passes levers for online attribution)
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
    tracker: DiversityTrackerV71 | None = None,
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
        tracker = _DEFAULT_TRACKER_V71

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
            "levers": _levers_of(q),          # online attribution input
        }

    accepted: list[dict] = []
    overflow: list[dict] = []
    attempts = 0
    max_attempts = max(num_queries, math.ceil(num_queries * max_attempt_factor))
    rejected_invalid = rejected_duplicate = rejected_plan_dup = 0
    rejected_plan_cap = rejected_skeleton = rejected_near_dup = 0

    # Wave cap so online attribution refreshes between waves (feedback bites on
    # accept, which happens once a wave's futures drain).
    wave_cap = max(1, generation_workers)

    while len(accepted) < num_queries and attempts < max_attempts:
        need = min(num_queries - len(accepted), max_attempts - attempts, wave_cap)
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
# Workload writer -- reuse v6's, retag v7.1, embed feedback state.
# ============================================================

def write_workload_directory(
    *,
    tracker: DiversityTrackerV71 | None = None,
    extra_report_fields: dict | None = None,
    **kwargs,
):
    extra = dict(extra_report_fields or {})
    extra["generator"] = GENERATOR_VERSION
    fb = {
        "mechanism": "online additive plan-feedback (self-attributed, no calibration)",
        "feedback_strength": V71_FEEDBACK_STRENGTH,
        "reweighting": "additive floor: weight = base * (1 + strength * rarity)",
    }
    if tracker is not None:
        snap = tracker.plan_feedback_snapshot()
        fb["feedback_enabled"] = tracker.feedback_enabled
        fb["plans_seen"] = snap["plans_seen"]
        fb["lever_draws"] = snap["lever_draws"]
        fb["operator_usage"] = snap["operator_usage"]
    extra.setdefault("plan_feedback", fb)
    return _v6.write_workload_directory(extra_report_fields=extra, **kwargs)
