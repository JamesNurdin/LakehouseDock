"""
query_generator_v7 -- plan-feedback QueryDock generator (forks v6).

Lineage: v7 forks **v6** (which forks v3). v6 computes each candidate's physical
plan but uses it only *destructively* -- reject exact plan-duplicates (min-NN>0)
and cap any one plan family. The plan is measured but it never steers what the
generator asks for next. v7 closes that loop.

What v7 adds (the one genuinely new lever)
------------------------------------------
F-1  Plan-space coverage feedback. Each accepted candidate's physical operator
     set updates a running operator-usage profile on the tracker. The shape /
     add-on draw is then re-weighted toward *under-represented* physical
     operators -- the plan-space analogue of v2's table/edge coverage weighting
     (SQL-Factory Eq. 7), lifted from the logical schema graph to the physical
     plan graph. Set feedback strength to 0 and v7 reduces *exactly* to v6, so
     v6 is the clean ablation baseline.

     The lever->operator affinity is itself LEARNED on the warmup corpus
     (presence-proportion lift), not hardcoded, so no operator names are baked
     into v7 and the map self-corrects to whatever this planner emits.

F-2  Operator "stopword" handling via idf. Operators that occur in essentially
     every plan (TableScan, Exchange, Project, Output, ...) carry no diversity
     signal. Rather than hand-maintain a denylist, v7 weights every operator by
     inverse document frequency measured on an unbiased calibration corpus:
     idf = log((N+1)/(df+1)). Ubiquitous operators get idf ~ 0 and self-
     neutralise; rare structural motifs get high idf. The rarity weight a lever
     receives is idf(op) * 1/(1+coverage_usage(op)) -- "is this operator
     informative at all" times "have I covered it yet".

F-3  Self-terminating calibration (``warm_up_operator_idf``). The idf table is
     estimated under the *unbiased* (feedback-off) generating distribution and
     then FROZEN before feedback is switched on -- otherwise the stopword
     weights would chase the very bias they exist to cancel. Calibration runs
     block-wise and stops itself, with NO tuned thresholds, when BOTH:
       (A) the Good-Turing missing mass f1/N (probability the next plan reveals
           an unseen operator) falls below the proportion sampling-error scale
           1/sqrt(N) -- the operator vocabulary is effectively closed; and
       (B) the bootstrap split-half Spearman rank agreement of the idf vector
           stops moving between blocks by more than its own bootstrap SD -- the
           idf *ranking* is reproducible under resampling.
     Both yardsticks are computed from the data, so "the index is warm" is an
     observed plateau, not a chosen constant. The calibration curves are
     returned for the report so the plateau is auditable.

Everything else is v6 unchanged: temperature floor, family/add-on/plan-shape
vocabulary, plan-graph dedup + family cap, attempt budget, report layout.

Public API is v6's, drop-in::

    load_schema, make_openai_client, warm_up_model,
    warm_up_operator_idf,                      # NEW (calibration)
    generate_query, generate_query_batch, write_workload_directory,
    fetch_table_columns, fetch_schema_table_columns
"""

from __future__ import annotations

import math
import random
import threading

from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed

# v7 forks v6. All heavy machinery is reached through the v6 module object so we
# do not repeat v6's long import list; only the feedback lever and calibration
# are new here. v6 already re-imported everything it needs from v3/v2, so every
# name below is a genuine attribute of the v6 module.
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
    "warm_up_operator_idf",
    "generate_query",
    "generate_query_batch",
    "write_workload_directory",
    "fetch_table_columns",
    "fetch_schema_table_columns",
    "DiversityTrackerV7",
    "V7_FEEDBACK_STRENGTH",
]

GENERATOR_VERSION = "query_generator_v7"


# ============================================================
# F-1 / F-2: feedback strength (the lever->operator affinity is LEARNED, not
# hardcoded -- see _learn_affinity + warm_up_operator_idf)
# ============================================================
# The generator cannot emit physical operators directly; it emits prompt
# directives (plan shapes + add-ons) that INDUCE operators, so feedback must act
# on the levers that produce the under-covered operators. Which lever induces
# which operator is NOT hardcoded: it is measured on the same unbiased warmup
# corpus that estimates idf, by presence-proportion lift (F-3). This keeps v7
# free of tuned operator names and makes the map self-correcting to whatever the
# planner actually emits on this schema/Trino version.

# How hard the rarity signal pushes. 0.0 == v6 exactly (static weights); 1.0 is
# the plain idf * 1/(1+usage) form; >1 sharpens toward the rarest operator. This
# is the ablation knob, NOT a statistical threshold.
V7_FEEDBACK_STRENGTH = 1.0


# ============================================================
# Tracker: v3 tracker + frozen idf table + live operator coverage
# ============================================================

class DiversityTrackerV7(DiversityTrackerV3):
    """v6/v3 tracker plus a plan-space *coverage* profile and a frozen idf table.

    Two separate structures, deliberately:
      * ``idf``            -- FROZEN inverse-document-frequency per operator,
        estimated once on the unbiased calibration corpus (F-3) and never
        updated during generation, so the stopword weights cannot drift toward
        the bias they exist to cancel.
      * ``operator_usage`` -- LIVE per-operator document-frequency counter over
        the workload accepted so far (presence per plan, not multiplicity -- so
        parallelism-driven Exchange fan-out cannot swamp the signal). This is
        the plan-space analogue of ``table_usage`` and drives the 1/(1+usage)
        coverage term.
    """

    def __init__(self):
        super().__init__()
        self.operator_usage: Counter = Counter()
        self.idf: dict[str, float] = {}
        self._default_idf: float = 0.0     # idf assigned to a never-calibrated op
        self.affinity: dict[str, list[str]] = {}   # LEARNED lever -> operators
        self.is_warm: bool = False

    def try_accept(self, **kwargs) -> str:
        """v3 accept, plus record operator PRESENCE into the live coverage
        counter on acceptance. ``plan_family`` (the coarse operator multiset) is
        already a v3 kwarg, so no call site changes."""
        plan_family = kwargs.get("plan_family")
        verdict = super().try_accept(**kwargs)
        if verdict == "accepted" and plan_family is not None:
            with self.lock:
                for op, _count in plan_family:      # +1 per plan the op appears in
                    self.operator_usage[op] += 1
        return verdict

    def freeze(self, idf: dict[str, float], affinity: dict[str, list[str]]) -> None:
        """Install the calibrated idf table AND the learned lever->operator
        affinity, then switch feedback ON. The live coverage counter is reset so
        generation coverage starts from zero (calibration plans are a throwaway
        corpus, not part of the workload)."""
        with self.lock:
            self.idf = dict(idf)
            self._default_idf = max(idf.values()) if idf else 0.0
            self.affinity = {k: list(v) for k, v in affinity.items()}
            self.operator_usage.clear()
            self.is_warm = True

    def plan_usage_snapshot(self) -> dict:
        with self.lock:
            return {"operators": dict(self.operator_usage)}

    def lever_rarity(self, lever_name: str) -> float:
        """idf(op) * 1/(1+coverage_usage(op)), averaged over the lever's affine
        operators. idf answers 'is this operator informative at all', the
        coverage term answers 'have I covered it yet'. Levers with no known
        operator affinity, or an un-warm tracker, are neutral (1.0)."""
        if not self.is_warm:
            return 1.0
        affine = self.affinity.get(lever_name)
        if not affine:
            return 1.0
        with self.lock:
            total = 0.0
            for op in affine:
                idf = self.idf.get(op, self._default_idf)
                cov = 1.0 / (1.0 + self.operator_usage.get(op, 0))
                total += idf * cov
            base = total / len(affine)
        return base ** V7_FEEDBACK_STRENGTH

    def reset(self):
        super().reset()
        with self.lock:
            self.operator_usage.clear()
            # idf / affinity / is_warm are intentionally preserved across
            # reset(): the calibrated tables survive a workload boundary.


_DEFAULT_TRACKER_V7 = DiversityTrackerV7()


# ============================================================
# Feedback-weighted shape draw (v6's sample_shape_spec, idf-re-weighted)
# ============================================================

def sample_shape_spec(rng: random.Random, tracker: DiversityTrackerV7 | None = None) -> dict:
    """v6's weighted family + add-on + plan-shape draw, but the add-on
    probabilities and plan-shape weights are scaled by ``tracker.lever_rarity``
    when the tracker is warm. Un-warm tracker (or None) == v6 exactly."""
    weights = [v["weight"] for v in PROMPT_VARIANTS]
    family = rng.choices(PROMPT_VARIANTS, weights=weights, k=1)[0]

    warm = tracker is not None and getattr(tracker, "is_warm", False)

    addons = []
    for spec in V6_ADDON_SPECS:
        if family["name"] == "simple" and not spec["simple_ok"]:
            continue
        if family["name"] in spec.get("skip_families", ()):
            continue
        p = spec["p"] * (tracker.lever_rarity(spec["name"]) if warm else 1.0)
        if rng.random() < min(1.0, p):
            addons.append(spec)

    plan_shape = None
    if family.get("join_all"):
        w = [p["weight"] * (tracker.lever_rarity(p["name"]) if warm else 1.0)
             for p in PLAN_SHAPES]
        plan_shape = rng.choices(PLAN_SHAPES, weights=w, k=1)[0]

    return {"family": family, "addons": addons, "plan_shape": plan_shape}


# ============================================================
# Single-query pipeline (v6's body; the ONLY change is the feedback-aware
# shape draw -- two lines, marked below)
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
    tracker: DiversityTrackerV7 | None = None,
    connected_fraction: float = 0.5,
    value_cache: dict | None = None,
    value_cache_lock=None,
    variant: dict | None = None,
) -> dict:
    """v6's single-query pipeline with the plan-feedback shape draw."""
    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()
    if tracker is None:
        tracker = _DEFAULT_TRACKER_V7
    if value_cache is None:
        value_cache = _v6._VALUE_CACHE
    if value_cache_lock is None:
        value_cache_lock = _v6._VALUE_CACHE_LOCK

    rng = random.Random(random_seed)

    if variant is not None:
        spec = {"family": variant, "addons": [], "plan_shape": None}
    else:
        # >>> the only substantive change vs v6.generate_query <<<
        spec = sample_shape_spec(rng, tracker=tracker)   # was: sample_shape_spec(rng)
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
        schema_json,
        n_tables,
        rng=rng,
        table_usage=usage["tables"],
        edge_usage=usage["edges"],
        connected_fraction=connected_fraction,
    )

    ddl_context = _v6.build_table_ddl_context(
        conn_factory=conn_factory,
        catalog=catalog,
        schema=trino_schema,
        tables=selected_tables,
        ddl_cache=ddl_cache,
        ddl_cache_lock=ddl_cache_lock,
    )

    columns_by_table = {
        t: _v6.fetch_table_columns_cached(
            conn_factory=conn_factory,
            catalog=catalog,
            schema=trino_schema,
            table=t,
            ddl_cache=ddl_cache,
            ddl_cache_lock=ddl_cache_lock,
        )
        for t in selected_tables
    }

    value_aid = _v6.build_value_aid(
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

    schema_context = _v6.build_schema_context(
        schema=schema_json,
        selected_tables=selected_tables,
        ddl_context=ddl_context,
        value_aid=value_aid,
    )

    has_join_rules = bool(_v6.get_relevant_relationships(schema_json, selected_tables))
    task = _v6.build_task_text(
        spec,
        n_tables=len(selected_tables),
        rng=rng,
        has_join_rules=has_join_rules,
    )

    # D-1 (inherited from v6): floor the base temperature hot, then add delta.
    base_temp = max(temperature, _v6.V6_TEMPERATURE_FLOOR)
    query_temperature = min(1.0, max(0.0, base_temp + family["temp_delta"]))

    sql_result = _v6.generate_sql(
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


# ============================================================
# F-3: self-terminating idf calibration
# ============================================================
# Statistics helpers -- pure Python so calibration adds no new dependency.

def _rank(vals: list[float]) -> list[float]:
    """Fractional (tie-averaged) ranks, 1-based."""
    order = sorted(range(len(vals)), key=lambda i: vals[i])
    ranks = [0.0] * len(vals)
    i = 0
    while i < len(vals):
        j = i
        while j + 1 < len(vals) and vals[order[j + 1]] == vals[order[i]]:
            j += 1
        avg = (i + j) / 2.0 + 1.0
        for k in range(i, j + 1):
            ranks[order[k]] = avg
        i = j + 1
    return ranks


def _pearson(a: list[float], b: list[float]) -> float:
    n = len(a)
    if n == 0:
        return 0.0
    ma, mb = sum(a) / n, sum(b) / n
    num = sum((a[i] - ma) * (b[i] - mb) for i in range(n))
    da = math.sqrt(sum((x - ma) ** 2 for x in a))
    db = math.sqrt(sum((x - mb) ** 2 for x in b))
    if da == 0.0 or db == 0.0:
        return 0.0
    return num / (da * db)


def _spearman(a: list[float], b: list[float]) -> float:
    return _pearson(_rank(a), _rank(b))


def _idf_vector(records: list[set[str]], vocab: list[str]) -> list[float]:
    """idf = log((N+1)/(df+1)) over the given plan records, aligned to vocab.
    Operators absent from these records get df=0 -> maximal idf (maximally rare),
    which is well defined, so split-half vectors are always comparable."""
    n = len(records)
    df: Counter = Counter()
    for ops in records:
        for op in ops:
            df[op] += 1
    return [math.log((n + 1) / (df.get(op, 0) + 1)) for op in vocab]


def _affinity_jaccard(recs_a: list[dict], recs_b: list[dict]) -> float:
    """Learn affinity on each half and return the mean per-lever Jaccard overlap
    of the affine operator sets -- how reproducible the LEARNED MAP is. Levers
    empty on both halves are skipped (no claim to disagree about)."""
    a = _learn_affinity(recs_a)["affinity"]
    b = _learn_affinity(recs_b)["affinity"]
    sims: list[float] = []
    for L in set(a) | set(b):
        sa, sb = set(a.get(L, [])), set(b.get(L, []))
        if not sa and not sb:
            continue
        union = len(sa | sb)
        sims.append(len(sa & sb) / union if union else 1.0)
    return sum(sims) / len(sims) if sims else 1.0


def _dist_stats(vals: list[float]) -> dict:
    vals = sorted(vals)
    n = len(vals)
    if n == 0:
        return {"mean": 0.0, "sd": 1.0, "p05": 0.0}
    mean = sum(vals) / n
    sd = math.sqrt(sum((v - mean) ** 2 for v in vals) / n) if n > 1 else 1.0
    p05 = vals[max(0, int(0.05 * n) - 1)]
    return {"mean": mean, "sd": sd, "p05": p05}


def _bootstrap_split_half(
    records: list[dict], rng: random.Random, resamples: int
) -> dict:
    """One split-half bootstrap yielding BOTH detectors from the same splits:
      * Spearman rank agreement of the idf vector  (idf ranking reproducibility)
      * mean per-lever Jaccard of the learned affinity (map reproducibility)
    Returns distribution stats (mean/sd/p05) for each, plus the vocab size."""
    op_records = [r["ops"] for r in records]
    vocab = sorted({op for ops in op_records for op in ops})
    if len(vocab) < 2 or len(records) < 4:
        return {"spearman": {"mean": 0.0, "sd": 1.0, "p05": 0.0},
                "jaccard": {"mean": 0.0, "sd": 1.0, "p05": 0.0},
                "n_vocab": len(vocab)}

    idx = list(range(len(records)))
    corrs: list[float] = []
    jaccs: list[float] = []
    for _ in range(resamples):
        rng.shuffle(idx)
        mid = len(idx) // 2
        a_i, b_i = idx[:mid], idx[mid:]
        va = _idf_vector([op_records[i] for i in a_i], vocab)
        vb = _idf_vector([op_records[i] for i in b_i], vocab)
        corrs.append(_spearman(va, vb))
        jaccs.append(_affinity_jaccard([records[i] for i in a_i],
                                       [records[i] for i in b_i]))

    return {"spearman": _dist_stats(corrs),
            "jaccard": _dist_stats(jaccs),
            "n_vocab": len(vocab)}


def _learn_affinity(records: list[dict]) -> dict:
    """Learn lever -> operator affinity from the unbiased corpus by presence-
    proportion lift. For lever L and operator op, keep op as affine to L iff the
    presence-rate difference P(op|L) - P(op|not L) exceeds its own (two-sample)
    standard error -- i.e. L raises op's presence beyond sampling noise. This is
    data-derived (no tuned operator names, no magic cutoff) and automatically
    excludes ubiquitous operators, whose rate is the same with or without any
    lever, so their lift is ~0.

    Each record is {'ops': set[str], 'levers': set[str]}. Returns
    {lever: [ops sorted by lift desc]} plus a diagnostic ``_support`` sidecar.
    """
    N = len(records)
    levers = sorted({L for r in records for L in r["levers"]})
    vocab = sorted({op for r in records for op in r["ops"]})
    affinity: dict[str, list[str]] = {}
    support: dict[str, dict] = {}

    for L in levers:
        with_L = [r for r in records if L in r["levers"]]
        without_L = [r for r in records if L not in r["levers"]]
        n1, n0 = len(with_L), len(without_L)
        support[L] = {"n_with": n1, "n_without": n0}
        if n1 == 0 or n0 == 0:
            affinity[L] = []
            continue
        scored: list[tuple[str, float]] = []
        for op in vocab:
            c1 = sum(1 for r in with_L if op in r["ops"])
            c0 = sum(1 for r in without_L if op in r["ops"])
            p1, p0 = c1 / n1, c0 / n0
            se = math.sqrt(p1 * (1 - p1) / n1 + p0 * (1 - p0) / n0)
            if p1 > p0 and (p1 - p0) > se:          # lift beyond one std error
                lift = p1 / p0 if p0 > 0 else p1 * N   # unbounded when p0==0
                scored.append((op, lift))
        scored.sort(key=lambda kv: kv[1], reverse=True)
        affinity[L] = [op for op, _lift in scored]
    return {"affinity": affinity, "_support": support}


def _generate_plan_family(
    *, conn_factory, schema_json, catalog, trino_schema, client,
    model_name, temperature, reasoning, min_tables, max_tables,
    seed, ddl_cache, ddl_cache_lock, calib_tracker,
) -> dict | None:
    """Generate ONE unbiased candidate and return
    {'ops': set of physical operators in its plan, 'levers': set of directives
    that were active (plan shape + add-ons)}, or None if the candidate is
    invalid. ``calib_tracker`` is a throwaway un-warm tracker so this uses the v6
    (feedback-off) generating distribution -- the correct reference for what
    'naturally occurring' means, and for measuring each lever's operator lift."""
    q = generate_query(
        conn_factory=conn_factory,
        schema_json=schema_json,
        catalog=catalog,
        trino_schema=trino_schema,
        client=client,
        model_name=model_name,
        temperature=temperature,
        reasoning=reasoning,
        min_tables=min_tables,
        max_tables=max_tables,
        random_seed=seed,
        ddl_cache=ddl_cache,
        ddl_cache_lock=ddl_cache_lock,
        tracker=calib_tracker,          # un-warm -> feedback OFF (== v6)
    )
    if not q.get("sql"):
        return None
    plan_json = _v6._explain_plan_json(conn_factory, q["sql"])
    if plan_json is None:
        return None
    _sig, family = _v6._plan_signatures(plan_json)
    if family is None:
        return None
    ops = {op for op, _count in family}       # presence set, not multiplicity
    levers = set(q.get("shape_addons", []))
    ps = q.get("plan_shape")
    if ps and ps != "none":
        levers.add(ps)
    return {"ops": ops, "levers": levers}


def warm_up_operator_idf(
    *,
    conn_factory,
    schema_json: dict,
    catalog: str,
    trino_schema: str,
    client_factory,
    model_name: str,
    tracker: DiversityTrackerV7 | None = None,
    temperature: float = 0.6,
    reasoning: str = "medium",
    min_tables: int = 2,
    max_tables: int = 8,
    random_seed: int | None = None,
    # --- computational-budget / resolution parameters (NOT decision thresholds) ---
    block_size: int = 24,
    min_blocks: int = 2,
    max_blocks: int = 20,
    bootstrap_resamples: int = 200,
    generation_workers: int = 4,
    ddl_cache: dict[str, list[dict]] | None = None,
    ddl_cache_lock=None,
) -> dict:
    """Estimate the operator idf table on the UNBIASED (feedback-off) generating
    distribution, block by block, and FREEZE it onto ``tracker`` once both
    data-derived plateau tests fire. Returns a calibration report (per-block
    curves for both detectors) for auditing.

    Stopping rule (no tuned thresholds):
      (A) Good-Turing missing mass  f1/N  <  1/sqrt(N)
          -- the vocabulary is effectively closed: the chance the next plan
             shows an unseen operator is below the proportion sampling error.
      (B) |mean_spearman(block) - mean_spearman(prev_block)| < bootstrap SD
          -- the split-half idf RANKING has stopped moving between blocks by
             more than its own resampling noise.
      (C) |mean_jaccard(block) - mean_jaccard(prev_block)| < bootstrap SD
          -- the split-half LEARNED AFFINITY map has likewise stopped moving by
             more than its own resampling noise (so rarely-drawn levers have
             accrued enough conditional support to stabilise, not just the
             marginal idf).
    All three must hold, after at least ``min_blocks`` blocks; ``max_blocks`` is
    a budget safeguard only.
    """
    if tracker is None:
        tracker = _DEFAULT_TRACKER_V7
    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()

    rng = random.Random(random_seed)
    boot_rng = random.Random((random_seed or 0) ^ 0x5F3759DF)

    thread_local = threading.local()

    def get_client():
        if not hasattr(thread_local, "client"):
            thread_local.client = client_factory()
        return thread_local.client

    calib_tracker = DiversityTrackerV7()      # throwaway, stays un-warm

    def worker(seed: int) -> dict | None:
        return _generate_plan_family(
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
            seed=seed,
            ddl_cache=ddl_cache,
            ddl_cache_lock=ddl_cache_lock,
            calib_tracker=calib_tracker,
        )

    records: list[dict] = []          # {'ops': set, 'levers': set} per valid plan
    block_curves: list[dict] = []
    prev_spearman_mean: float | None = None
    prev_jaccard_mean: float | None = None
    stopped_reason = "max_blocks"

    for block in range(1, max_blocks + 1):
        seeds = [rng.randint(0, 10**9) for _ in range(block_size)]
        with ThreadPoolExecutor(max_workers=min(generation_workers, block_size)) as ex:
            futures = [ex.submit(worker, s) for s in seeds]
            for fut in as_completed(futures):
                try:
                    rec = fut.result()
                except Exception as e:
                    print(f"[calib] generation failed: {type(e).__name__}: {e}")
                    continue
                if rec:
                    records.append(rec)

        N = len(records)
        if N == 0:
            continue

        op_records = [r["ops"] for r in records]

        # (A) Good-Turing missing mass vs the proportion sampling-error scale.
        global_df: Counter = Counter()
        for ops in op_records:
            for op in ops:
                global_df[op] += 1
        f1 = sum(1 for op, c in global_df.items() if c == 1)
        missing_mass = f1 / N
        se_scale = 1.0 / math.sqrt(N)
        cond_A = missing_mass < se_scale

        # (B) idf-ranking stability and (C) affinity-map stability, from one
        # split-half bootstrap. Each is judged against its OWN resampling SD.
        boot = _bootstrap_split_half(records, boot_rng, bootstrap_resamples)
        sp, jc = boot["spearman"], boot["jaccard"]

        if prev_spearman_mean is None:
            cond_B, sp_delta = False, None
        else:
            sp_delta = abs(sp["mean"] - prev_spearman_mean)
            cond_B = sp_delta < sp["sd"]
        prev_spearman_mean = sp["mean"]

        if prev_jaccard_mean is None:
            cond_C, jc_delta = False, None
        else:
            jc_delta = abs(jc["mean"] - prev_jaccard_mean)
            cond_C = jc_delta < jc["sd"]
        prev_jaccard_mean = jc["mean"]

        block_curves.append({
            "block": block,
            "n_plans": N,
            "n_vocab": boot["n_vocab"],
            "missing_mass": round(missing_mass, 4),
            "se_scale": round(se_scale, 4),
            "cond_A_vocab_closed": cond_A,
            "spearman_mean": round(sp["mean"], 4),
            "spearman_sd": round(sp["sd"], 4),
            "spearman_block_delta": round(sp_delta, 4) if sp_delta is not None else None,
            "cond_B_ranking_stable": cond_B,
            "affinity_jaccard_mean": round(jc["mean"], 4),
            "affinity_jaccard_sd": round(jc["sd"], 4),
            "affinity_block_delta": round(jc_delta, 4) if jc_delta is not None else None,
            "cond_C_affinity_stable": cond_C,
        })

        if block >= min_blocks and cond_A and cond_B and cond_C:
            stopped_reason = "converged"
            break

    # Freeze idf AND the learned affinity over the full calibration corpus, then
    # switch feedback ON.
    N = len(records)
    final_df: Counter = Counter()
    for r in records:
        for op in r["ops"]:
            final_df[op] += 1
    idf = {op: math.log((N + 1) / (df + 1)) for op, df in final_df.items()}
    learned = _learn_affinity(records)
    affinity = learned["affinity"]
    tracker.freeze(idf, affinity)

    # A reportable stopword list (idf ~ 0 == occurs in ~every plan). Diagnostic
    # only -- the continuous idf weighting already handles these; this is the
    # sentence that pre-empts the "you didn't account for scans/exchanges"
    # reviewer objection.
    stopwords = sorted(
        (op for op, v in idf.items() if v < (0.5 / math.sqrt(max(N, 1)))),
        key=lambda op: final_df[op], reverse=True,
    )

    report = {
        "calibration": "operator_idf",
        "generator": GENERATOR_VERSION,
        "n_plans": N,
        "n_operators": len(idf),
        "stopped_reason": stopped_reason,
        "feedback_strength": V7_FEEDBACK_STRENGTH,
        "block_curves": block_curves,
        "structural_stopwords": stopwords,
        "idf_table": {op: round(v, 4) for op, v in
                      sorted(idf.items(), key=lambda kv: kv[1], reverse=True)},
        "learned_affinity": affinity,
        "affinity_support": learned["_support"],
    }
    print(
        f"[calib] idf + affinity frozen after {N} plans / {len(block_curves)} "
        f"blocks ({stopped_reason}); {len(idf)} operators, "
        f"{len(stopwords)} structural stopwords, "
        f"{sum(1 for v in affinity.values() if v)} levers with learned operators"
    )
    return report


# ============================================================
# Batch generation -- v6's loop, v7 tracker/generate_query, plus an adaptive
# wave size so plan-feedback actually propagates between waves.
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
    tracker: DiversityTrackerV7 | None = None,
    connected_fraction: float = 0.5,
    skeleton_cap: int = 12,
    plan_signature_cap: int = 3,      # inherited from v6 (D-5)
    max_attempt_factor: float = 4.0,  # inherited from v6 (runtime bound)
) -> list[dict]:
    """v6's plan-space novelty control, but candidates are drawn against the v7
    plan-feedback tracker and waves are capped so the operator-usage profile
    refreshes between waves (feedback only propagates on accept, which happens
    once a wave's futures are drained -- so a smaller wave == tighter feedback).
    Wave size and ``V7_FEEDBACK_STRENGTH`` are the ablation surface."""
    rng = random.Random(random_seed)

    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()
    if tracker is None:
        tracker = _DEFAULT_TRACKER_V7

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

    # F-1 wave cap: keep each parallel wave ~worker-width so the operator-usage
    # profile is re-snapshotted often (feedback bites between waves, not within).
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
                else:  # "duplicate"
                    rejected_duplicate += 1

    # graceful degradation within the SAME budget (v6): fill any shortfall from
    # capped-but-unique queries; plan duplicates are never filler, so min-NN>0.
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
# Workload writer -- reuse v6's, retag as v7, embed the calibration report.
# ============================================================

def write_workload_directory(
    *,
    calibration_report: dict | None = None,
    extra_report_fields: dict | None = None,
    **kwargs,
):
    """v6's writer, retagged v7. Pass ``calibration_report`` (from
    ``warm_up_operator_idf``) to embed the idf-plateau evidence in the report.
    v6's writer does ``report.update(extra_report_fields)`` last, so overriding
    ``generator`` here is honoured."""
    extra = dict(extra_report_fields or {})
    extra["generator"] = GENERATOR_VERSION
    if calibration_report is not None:
        extra["operator_idf_calibration"] = calibration_report
    extra.setdefault("feedback", {
        "mechanism": "plan-space coverage feedback (idf-weighted operator rarity)",
        "feedback_strength": V7_FEEDBACK_STRENGTH,
        "lever_operator_affinity": "learned on warmup corpus; see operator_idf_calibration.learned_affinity",
    })
    return _v6.write_workload_directory(extra_report_fields=extra, **kwargs)
