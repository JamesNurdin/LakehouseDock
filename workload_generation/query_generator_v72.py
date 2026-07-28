"""
query_generator_v72 -- ceiling-raising plan-feedback generator (forks v6).

The v7 -> v7.1 -> v7.2 arc
--------------------------
v7   multiplicative feedback COLLAPSED the shape distribution (Vendi 71.6->54).
v7.1 additive floor made feedback harm-free but it converged to v6 (68.8~71.6):
     coverage feedback is *redistribution*, and redistribution cannot raise the
     motif-vocabulary ceiling that Vendi is bounded by. In the saturated N=1000
     regime v6 already hits that ceiling, so there is no headroom.

v7.2 therefore stops trying to redistribute within the ceiling and instead wires
the feedback signal to the levers that RAISE the ceiling:

  KEEP (from v7.1 -- these are why it stopped collapsing, so they stay):
    * additive floor: weight = base * (1 + strength * rarity), rarity in [0,1].
      Never annihilates a lever (add-ons keep a strict probability floor).
    * online self-attribution: no offline calibration; lever->motif association
      is accumulated during generation.
    * coverage self-discounting: 1/(1+usage) so ubiquitous motifs need no idf.

  NEW (the ceiling-raising machinery):
    N-1  N-GRAM reward. Coverage/attribution move from single operators to
         operator BIGRAMS (plan-graph edges) -- the vocabulary Vendi actually
         scores. Trivial plumbing edges (Exchange/Project/Scan/Limit/TopN...) are
         excluded so the loop chases structural motifs, not surface artifacts.
    N-2  UCB EXPLORATION. rarity gains a bandit term c*sqrt(ln N/(1+draws)) so
         rarely-drawn / exotic levers get tried and their motif yield discovered,
         instead of only exploiting what is already known.
    N-3  EXOTIC ARMS. Recursive CTEs / correlated subqueries / LATERAL joins --
         off in v6 -- are added as low-base feedback arms. They emit operators v6
         never produces, so covering them lifts the ceiling (cf. v6_exotic>v6).
    N-4  PLATEAU ESCALATION. The loop tracks the motif discovery rate (new unique
         n-grams per accepted plan). When it plateaus (ceiling being hit) it
         escalates the GENERATION-side knobs feedback cannot otherwise touch --
         temperature and plan size -- the only levers that move the ceiling.

Universal switch: ``plan_feedback`` (via ``tracker.feedback_enabled``). When off,
every rarity is 0, exotic arms are dropped, escalation is 0 -> v7.2 == v6 exactly.

Caveat (intended): v7.2 trades v7.1's safety for a shot past v6. Exotics raise the
invalid rate and cost; aggressive exploration can lower Vendi if it over-spends on
low-yield arms. The additive floor + capped exotic base + capped escalation bound
that risk but do not remove it.
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
# Plan-graph DAG builder -- same one the diversity notebook and _plan_signatures
# use, so v7.2 diversifies exactly what the metrics score.
from loader.parser import build_trino_dag

__all__ = [
    "load_schema",
    "make_openai_client",
    "warm_up_model",
    "generate_query",
    "generate_query_batch",
    "write_workload_directory",
    "fetch_table_columns",
    "fetch_schema_table_columns",
    "DiversityTrackerV72",
    "V72_FEEDBACK_STRENGTH",
    "TRIVIAL_OPERATORS",
]

GENERATOR_VERSION = "query_generator_v72"

# ---- tunables (ablation knobs, NOT statistical thresholds) ----
V72_FEEDBACK_STRENGTH = 1.0     # additive strength; 0.0 == v6
V72_EXPLORE_C = 0.3             # UCB exploration coefficient (N-2)
V72_EXOTIC_BASE_P = 0.04        # base fire-rate of exotic arms when feedback on (N-3)
V72_ESC_WINDOW = 100            # accepted-plans window for discovery-rate plateau (N-4)
V72_ESC_TEMP_STEP = 0.02        # temperature added per escalation level
V72_ESC_TABLE_STEP = 2          # max_tables added per escalation level
V72_MAX_ESCALATION = 3          # cap on escalation levels

# Surface / plumbing operators: byproducts of SQL clauses and distribution, not
# plan-graph structure. A bigram whose BOTH endpoints are trivial carries no
# structural diversity, so it is excluded from the n-gram reward (N-1). This is
# the one small curated set in v7.2; everything else is data-driven.
TRIVIAL_OPERATORS = frozenset({
    "Output", "RemoteSource", "LocalExchange", "RemoteExchange", "Exchange",
    "Project", "ScanFilterProject", "ScanFilter", "ScanProject", "TableScan",
    "Filter", "FilterProject", "Limit", "LimitPartial", "TopN", "TopNPartial",
    "TopNRanking", "DistinctLimit", "DistinctLimitPartial", "Sort", "LocalMerge",
    "RemoteMerge", "PartialSort", "AssignUniqueId", "Values",
})

# Exotic arms (N-3): v6's exotic add-ons, re-based to a small feedback-gated
# probability so exploration can lift them without flooding invalids.
_V72_EXOTIC_ARMS = [dict(a, p=V72_EXOTIC_BASE_P) for a in _v6._V6_EXOTIC_ADDONS]


# ============================================================
# Plan-graph n-gram extraction
# ============================================================

def _plan_ngrams(plan_json) -> set:
    """Structural operator bigrams (parent, child, edge_type) of a plan, with
    both-trivial edges dropped. This is the motif unit the reward targets."""
    dag = build_trino_dag(plan_json)
    nodes = dag.get("nodes", {})
    grams = set()
    for src, dst, etype in dag.get("edges", []):
        pn = nodes.get(src, {}).get("name", "?")
        cn = nodes.get(dst, {}).get("name", "?")
        if pn in TRIVIAL_OPERATORS and cn in TRIVIAL_OPERATORS:
            continue
        grams.add((pn, cn, etype))
    return grams


# ============================================================
# Tracker: v3 tracker + online n-gram feedback + UCB + escalation
# ============================================================

class DiversityTrackerV72(DiversityTrackerV3):
    """v3 tracker plus v7.2 online plan-space state:

      * ``ngram_usage``        -- document frequency of structural operator
        bigrams (drives the coverage term 1/(1+usage)).
      * ``lever_ngram_cooc`` / ``lever_draws`` -- online attribution of motifs to
        the levers active when they occurred (replaces any calibration).
      * ``discovery``          -- new unique n-grams contributed per accepted
        plan; its decline drives plateau escalation.
      * ``_esc_level``         -- current generation-side escalation level.

    ``feedback_enabled`` toggles the whole mechanism off (== v6).
    """

    def __init__(self):
        super().__init__()
        self.operator_usage: Counter = Counter()      # kept for reporting
        self.ngram_usage: Counter = Counter()
        self.lever_draws: Counter = Counter()
        self.lever_ngram_cooc: dict[str, Counter] = defaultdict(Counter)
        self.discovery: list[int] = []
        self.plans_seen: int = 0
        self._esc_level: int = 0
        self.feedback_enabled: bool = True

    def try_accept(self, **kwargs) -> str:
        levers = kwargs.pop("levers", ()) or ()
        plan_ngrams = kwargs.pop("plan_ngrams", None)
        plan_family = kwargs.get("plan_family")
        verdict = super().try_accept(**kwargs)
        if verdict == "accepted":
            with self.lock:
                self.plans_seen += 1
                if plan_family is not None:
                    for op, _c in plan_family:
                        self.operator_usage[op] += 1
                grams = plan_ngrams or set()
                new = sum(1 for g in grams if self.ngram_usage.get(g, 0) == 0)
                self.discovery.append(new)
                for g in grams:
                    self.ngram_usage[g] += 1
                for L in levers:
                    self.lever_draws[L] += 1
                    cooc = self.lever_ngram_cooc[L]
                    for g in grams:
                        cooc[g] += 1
                self._maybe_escalate_locked()
        return verdict

    # ---- N-2: exploit (n-gram coverage) + UCB explore ----
    def lever_rarity(self, lever_name: str) -> float:
        if not self.feedback_enabled:
            return 0.0
        with self.lock:
            draws = self.lever_draws.get(lever_name, 0)
            exploit = 0.0
            cooc = self.lever_ngram_cooc.get(lever_name)
            if draws > 0 and cooc:
                for g, c in cooc.items():
                    rate = c / draws                              # P(motif|lever)
                    need = 1.0 / (1.0 + self.ngram_usage.get(g, 0))
                    v = rate * need
                    if v > exploit:
                        exploit = v
            explore = V72_EXPLORE_C * math.sqrt(
                math.log(1 + self.plans_seen) / (1 + draws)
            )
            return min(1.0, exploit + explore)

    # ---- N-4: plateau escalation of generation-side knobs ----
    def _maybe_escalate_locked(self) -> None:
        n = self.plans_seen
        if n < 2 * V72_ESC_WINDOW or n % V72_ESC_WINDOW != 0:
            return
        if self._esc_level >= V72_MAX_ESCALATION:
            return
        baseline = self.discovery[:V72_ESC_WINDOW]
        recent = self.discovery[-V72_ESC_WINDOW:]
        base_rate = sum(baseline) / len(baseline)
        recent_rate = sum(recent) / len(recent)
        # discovery has fallen to below half its early rate -> ceiling is being
        # hit; spend budget on raising it.
        if base_rate > 0 and recent_rate < 0.5 * base_rate:
            self._esc_level += 1

    def escalation_snapshot(self) -> dict:
        if not self.feedback_enabled:
            return {"level": 0, "temp_bonus": 0.0, "table_bonus": 0}
        with self.lock:
            lvl = self._esc_level
        return {
            "level": lvl,
            "temp_bonus": lvl * V72_ESC_TEMP_STEP,
            "table_bonus": lvl * V72_ESC_TABLE_STEP,
        }

    def plan_feedback_snapshot(self) -> dict:
        with self.lock:
            return {
                "plans_seen": self.plans_seen,
                "escalation_level": self._esc_level,
                "unique_ngrams": len(self.ngram_usage),
                "lever_draws": dict(self.lever_draws),
                "operator_usage": dict(self.operator_usage),
                "discovery_rate_first100": (
                    sum(self.discovery[:100]) / max(1, len(self.discovery[:100]))
                ),
                "discovery_rate_last100": (
                    sum(self.discovery[-100:]) / max(1, len(self.discovery[-100:]))
                ),
            }

    def reset(self):
        super().reset()
        with self.lock:
            self.operator_usage.clear()
            self.ngram_usage.clear()
            self.lever_draws.clear()
            self.lever_ngram_cooc.clear()
            self.discovery.clear()
            self.plans_seen = 0
            self._esc_level = 0


_DEFAULT_TRACKER_V72 = DiversityTrackerV72()


# ============================================================
# Additive-floor shape draw with exotic arms
# ============================================================

def _boost(tracker: DiversityTrackerV72 | None, name: str) -> float:
    if tracker is None or not getattr(tracker, "feedback_enabled", False):
        return 1.0
    return 1.0 + V72_FEEDBACK_STRENGTH * tracker.lever_rarity(name)


def sample_shape_spec(rng: random.Random, tracker: DiversityTrackerV72 | None = None) -> dict:
    """v6's draw with additive-floor boost, plus exotic arms when feedback is on.
    Off -> exactly v6 (v6 add-on set, no boost, no exotics)."""
    weights = [v["weight"] for v in PROMPT_VARIANTS]
    family = rng.choices(PROMPT_VARIANTS, weights=weights, k=1)[0]

    warm = tracker is not None and getattr(tracker, "feedback_enabled", False)
    addon_specs = (list(V6_ADDON_SPECS) + _V72_EXOTIC_ARMS) if warm else V6_ADDON_SPECS

    addons = []
    for spec in addon_specs:
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
# Single-query pipeline (v6 body; feedback shape draw + escalation)
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
    tracker: DiversityTrackerV72 | None = None,
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
        tracker = _DEFAULT_TRACKER_V72
    if value_cache is None:
        value_cache = _v6._VALUE_CACHE
    if value_cache_lock is None:
        value_cache_lock = _v6._VALUE_CACHE_LOCK

    rng = random.Random(random_seed)

    if variant is not None:
        spec = {"family": variant, "addons": [], "plan_shape": None}
    else:
        spec = sample_shape_spec(rng, tracker=tracker)
    family = spec["family"]

    # N-4: escalate plan size when the motif discovery rate has plateaued.
    esc = tracker.escalation_snapshot()
    max_tables_eff = max_tables + int(esc["table_bonus"])

    n_range = family.get("n_tables_range")
    if n_range == "high":
        lo = max(min_tables, min(5, max_tables_eff))
        n_tables = rng.randint(lo, max_tables_eff)
    elif n_range is not None:
        lo, hi = n_range
        n_tables = rng.randint(max(1, lo), max(1, hi))
    else:
        n_tables = rng.randint(min_tables, max_tables_eff)

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

    # N-4: escalate temperature too (raises the reachable-motif ceiling).
    base_temp = max(temperature, _v6.V6_TEMPERATURE_FLOOR)
    query_temperature = min(1.0, max(0.0, base_temp + family["temp_delta"] + esc["temp_bonus"]))

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
        "escalation_level": esc["level"],
    }


def _levers_of(q: dict) -> set:
    levers = set(q.get("shape_addons", []))
    ps = q.get("plan_shape")
    if ps and ps != "none":
        levers.add(ps)
    return levers


# ============================================================
# Batch generation (v6 loop; passes levers + n-grams for attribution)
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
    tracker: DiversityTrackerV72 | None = None,
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
        tracker = _DEFAULT_TRACKER_V72

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
                    q["plan_ngrams"] = set()
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
            "plan_ngrams": q.get("plan_ngrams") or set(),
        }

    accepted: list[dict] = []
    overflow: list[dict] = []
    attempts = 0
    max_attempts = max(num_queries, math.ceil(num_queries * max_attempt_factor))
    rejected_invalid = rejected_duplicate = rejected_plan_dup = 0
    rejected_plan_cap = rejected_skeleton = rejected_near_dup = 0

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
# Workload writer -- reuse v6's, retag v7.2, embed feedback state.
# ============================================================

def write_workload_directory(
    *,
    tracker: DiversityTrackerV72 | None = None,
    extra_report_fields: dict | None = None,
    **kwargs,
):
    extra = dict(extra_report_fields or {})
    extra["generator"] = GENERATOR_VERSION
    fb = {
        "mechanism": "ceiling-raising plan-feedback (n-gram reward + UCB + exotic arms + plateau escalation)",
        "feedback_strength": V72_FEEDBACK_STRENGTH,
        "explore_c": V72_EXPLORE_C,
        "exotic_base_p": V72_EXOTIC_BASE_P,
        "reweighting": "additive floor: weight = base * (1 + strength * rarity)",
        "reward_unit": "structural operator bigrams (trivial-plumbing edges excluded)",
    }
    if tracker is not None:
        fb.update(tracker.plan_feedback_snapshot())
        fb["feedback_enabled"] = tracker.feedback_enabled
    extra.setdefault("plan_feedback", fb)
    return _v6.write_workload_directory(extra_report_fields=extra, **kwargs)
