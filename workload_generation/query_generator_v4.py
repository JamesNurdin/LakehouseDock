"""
query_generator_v4 -- entropy-flattening QueryDock generator (v3 + H1).

Drop-in replacement for ``query_generator_v3`` (and thus v2). The public API is
identical -- it exports every name ``Lakehouse`` imports::

    load_schema, make_openai_client, warm_up_model,
    generate_query, generate_query_batch, write_workload_directory,
    fetch_table_columns, fetch_schema_table_columns

so the only change required in ``trino_stack/lakehouse.py`` is swapping::

    from workload_generation.query_generator_v3 import ( ... )
    # ->
    from workload_generation.query_generator_v4 import ( ... )

Why v4
------
v3 recovered plan-instance diversity (Vendi, plan uniqueness, min-NN > 0 -- the
only generator with zero duplicate plans at 1000 queries) while holding v2.1's
schema-diversity gains. The one residual weakness is the **normalised operator
n-gram entropy**: v3 has the richest operator/motif vocabulary of any generator
(33 operator types, 558 trigrams) but the *most concentrated* one -- a heavy
"join -> aggregate -> scan" spine plus a long thin tail -- so the normalised
entropy (H / log k, i.e. *evenness*) is the lowest in the field, and it worsens
with scale as the common spine accumulates.

v4 adds **H1: soft, frequency-weighted plan-motif acceptance**. It keeps a
running histogram of the operator trigrams the metric itself counts
(``loader.workload_analysis.operator_ngram_counts``), and accepts each candidate
with a probability that falls as the candidate's motifs become over-represented.
This is the plan-space analogue of the ``1/(1+usage)`` weighting v2/v3 already
trust for tables, FK edges and columns -- it *targets the distribution*: mass is
pulled off the dominant motif and rare motifs pass more often, pushing the
accepted trigram distribution toward uniform, which is exactly what the entropy
metric rewards.

Scale-invariant form (important)
--------------------------------
A literal ``1/(1+usage)`` on a raw trigram count would stall at scale: usage
grows without bound, so late candidates would be rejected almost surely. Because
the target metric is *normalised* entropy (evenness), v4 instead measures a
candidate's motif frequency *relative to the current average* and only
down-weights **above-average** plans::

    expected  = total_trigram_observations / number_of_distinct_trigrams
    over      = max(0, mean_usage(candidate_trigrams) / expected - 1)
    p_accept  = 1 / (1 + soft_weight_strength * over)

An average-or-rarer plan has ``over = 0`` and always passes, so the mechanism
self-limits as the distribution flattens (no stalling) and never suppresses
genuinely novel structure -- it only thins the head. ``soft_weight_strength``
trades evenness against wall-clock (more rejection -> slower); set it to 0.0 to
fall back to exactly v3's behaviour.

Everything else is inherited unchanged from v3: the coverage-aware selection
layer, the rebalanced families + plan-shape axis (B), the exact plan-graph
dedup and plan-family cap (A), and the SQL/skeleton novelty checks. Schema
diversity is untouched because H1 gates only plan *structure*, never table /
column / edge selection.
"""

from __future__ import annotations

import json
import math
import random
import threading

from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path

from loader.parser import build_trino_dag
from loader.workload_analysis import operator_ngram_counts

# v4 layers on v3 (which layers on v2). Selection + B + A are reused verbatim.
from workload_generation.query_generator_v3 import (
    # --- drop-in API names re-exported unchanged ---
    load_schema,
    make_openai_client,
    warm_up_model,
    fetch_table_columns,
    fetch_schema_table_columns,
    generate_query,                # single-query pipeline is identical to v3
    # --- v3 machinery v4 composes with ---
    DiversityTrackerV3,
    _explain_plan_json,
    _edge_key,
    _dedup_key,
    _skeleton_key,
    _bare_column_name,
    get_relevant_relationships,
    PROMPT_VARIANTS,
    PLAN_SHAPES,
    ADDON_SPECS,
    INSTRUCTIONS_TEMPLATE,
    PROMPT_TEMPLATE,
    ensure_dir,
    WORKLOAD_ROOT,
    MODEL_NAME,
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
    "DiversityTrackerV4",
]

GENERATOR_VERSION = "query_generator_v4"

# Default strength of the soft motif down-weighting. 0.0 == v3 behaviour.
# A gentle default: on head-heavy candidate streams a high strength rejects
# aggressively (more attempts -> slower), so start low (~0.5-1.0) and raise it
# while watching wall-clock and the realised operator_ngram_entropy gain.
DEFAULT_SOFT_WEIGHT_STRENGTH = 1.0

# Deterministic-per-candidate salt for the acceptance roll (keeps the roll
# reproducible from the candidate's seed and independent of thread timing).
_ROLL_SALT = 0x9E3779B9


# ------------------------------------------------------------
# Plan features: exact-dedup signature + coarse family + metric trigrams
# ------------------------------------------------------------

def _plan_features(plan_json):
    """
    Return (fine_signature, coarse_family, trigram_counts) for one plan, built
    from a single DAG pass.

      * fine_signature  -- hash(operator multiset + operator-edge bigrams); the
        A-mechanism exact plan-duplicate key (min-NN 0.0 guard).
      * coarse_family   -- sorted operator multiset; the A-mechanism plan cap key.
      * trigram_counts  -- Counter of root->node operator trigrams, computed with
        the *same* function the ``operator_ngram_entropy`` metric uses, so H1
        down-weights exactly what the notebook scores.
    """
    dag = build_trino_dag(plan_json)
    nodes = dag.get("nodes", {})
    if not nodes:
        return None, None, None

    op_counts = Counter(n.get("name", "?") for n in nodes.values())
    coarse_family = tuple(sorted(op_counts.items()))

    bigrams = Counter()
    for src, dst, etype in dag.get("edges", []):
        pn = nodes.get(src, {}).get("name", "?")
        cn = nodes.get(dst, {}).get("name", "?")
        bigrams[(pn, cn, etype)] += 1
    fine = hash((coarse_family, tuple(sorted(bigrams.items()))))

    trigrams = operator_ngram_counts(dag, n=3, include_edge_types=("child",))
    return fine, coarse_family, trigrams


# ------------------------------------------------------------
# H1: soft frequency-weighted plan-motif tracker
# ------------------------------------------------------------

class DiversityTrackerV4(DiversityTrackerV3):
    """
    v3's tracker (selection usage + SQL/skeleton novelty + exact plan dedup +
    plan-family cap) plus H1: a running histogram of operator trigrams
    (``trigram_usage``) used to down-weight over-represented plan motifs at
    acceptance time.

    Selection bookkeeping (``table_usage`` / ``edge_usage`` / ``column_usage``)
    and ``usage_snapshot`` are inherited unchanged, so schema-diversity
    behaviour is byte-for-byte v3.
    """

    def __init__(self):
        super().__init__()
        self.trigram_usage: Counter = Counter()

    def _soft_p_accept(self, trigram_counts, strength: float) -> float:
        """Scale-invariant acceptance probability: 1 for average-or-rarer plans,
        decreasing only for plans whose motifs are above the current average
        frequency. See the module docstring for the derivation."""
        if not strength or not trigram_counts:
            return 1.0
        n_distinct = len(self.trigram_usage)
        total = sum(self.trigram_usage.values())
        if n_distinct == 0 or total == 0:
            return 1.0
        expected = total / n_distinct
        if expected <= 0:
            return 1.0
        keys = list(trigram_counts.keys())
        cand_mean = sum(self.trigram_usage.get(g, 0) for g in keys) / len(keys)
        over = max(0.0, cand_mean / expected - 1.0)
        return 1.0 / (1.0 + strength * over)

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
        plan_trigrams: Counter | None = None,
        soft_weight_strength: float = 0.0,
        soft_roll: float | None = None,
        enforce_caps: bool = True,
    ) -> str:
        """
        Atomically test-and-record a candidate. Returns one of:
        "accepted", "duplicate", "plan_duplicate", "soft_rejected",
        "plan_capped", "near_duplicate", "skeleton_capped".
        """
        fine_key = (skeleton, tuple(sorted(tables)))
        with self.lock:
            if sql_key in self.seen_sql:
                return "duplicate"
            if enforce_caps:
                # A: never emit a literal duplicate physical plan.
                if plan_sig is not None and plan_sig in self.seen_plan:
                    return "plan_duplicate"
                # H1: probabilistically thin over-represented plan motifs.
                if soft_weight_strength and soft_roll is not None and plan_trigrams:
                    if soft_roll > self._soft_p_accept(plan_trigrams, soft_weight_strength):
                        return "soft_rejected"
                # A: hard ceiling so no single plan family runs away if
                # soft_weight_strength is set low / zero.
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
            if plan_trigrams:
                # record with multiplicity so the histogram matches the metric's
                # trigram frequency distribution.
                self.trigram_usage.update(plan_trigrams)
            self.table_usage.update(tables)
            self.edge_usage.update(edges)
            self.column_usage.update(columns)
            return "accepted"

    def reset(self):
        # Fully overridden (threading.Lock is not reentrant).
        with self.lock:
            self.table_usage.clear()
            self.edge_usage.clear()
            self.column_usage.clear()
            self.seen_sql.clear()
            self.skeletons.clear()
            self.seen_fine.clear()
            self.seen_plan.clear()
            self.plan_families.clear()
            self.trigram_usage.clear()


_DEFAULT_TRACKER_V4 = DiversityTrackerV4()


# ------------------------------------------------------------
# Batch generation with H1 layered on v3's A/B controls
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
    # v4 optional knobs (defaults preserve the drop-in API)
    tracker: DiversityTrackerV3 | None = None,
    connected_fraction: float = 0.5,
    skeleton_cap: int = 12,
    plan_signature_cap: int = 12,
    soft_weight_strength: float = DEFAULT_SOFT_WEIGHT_STRENGTH,
    max_attempt_factor: float = 5.0,
) -> list[dict]:
    """
    Batch generation with H1 soft motif flattening layered on v3's exact plan
    dedup + plan-family cap (A) and SQL/skeleton control.

    Each candidate is EXPLAINed once (validating it and yielding its plan
    signatures + trigrams). Acceptance rejects, in order: SQL duplicates, exact
    plan duplicates, then -- probabilistically -- over-represented plan motifs
    (H1), then over-represented plan families, (skeleton, table-set)
    near-duplicates, and over-represented SQL skeletons. Soft/near/cap rejects
    are held as overflow and used as filler if the attempt budget
    (``num_queries * max_attempt_factor``) runs out, so the caller always
    receives ``num_queries`` queries.

    ``soft_weight_strength = 0.0`` reproduces v3 exactly.
    """
    rng = random.Random(random_seed)

    if ddl_cache is None:
        ddl_cache = {}
    if ddl_cache_lock is None:
        ddl_cache_lock = threading.Lock()
    if tracker is None:
        tracker = _DEFAULT_TRACKER_V4

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
                fine, coarse, trigrams = _plan_features(plan_json)
                q["plan_valid"] = fine is not None
                q["plan_sig"] = fine
                q["plan_family"] = coarse
                q["plan_trigrams"] = trigrams
                # deterministic per-candidate roll for the probabilistic accept
                q["soft_roll"] = random.Random(seed ^ _ROLL_SALT).random()
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
    rejected_soft = 0
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
                    plan_trigrams=q.get("plan_trigrams"),
                    soft_weight_strength=soft_weight_strength,
                    soft_roll=q.get("soft_roll"),
                )

                if verdict == "accepted":
                    accepted.append(q)
                elif verdict == "plan_duplicate":
                    rejected_plan_dup += 1
                elif verdict == "soft_rejected":
                    rejected_soft += 1
                    overflow.append(q)
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

    # graceful degradation: fill any shortfall from held-back but unique queries
    while len(accepted) < num_queries and overflow:
        q = overflow.pop(0)
        verdict = tracker.try_accept(
            **accept_args(q),
            skeleton_cap=skeleton_cap,
            plan_sig=q.get("plan_sig"),
            plan_family=q.get("plan_family"),
            plan_signature_cap=plan_signature_cap,
            plan_trigrams=q.get("plan_trigrams"),
            soft_weight_strength=soft_weight_strength,
            soft_roll=q.get("soft_roll"),
            enforce_caps=False,
        )
        if verdict == "accepted":
            accepted.append(q)

    if any((rejected_invalid, rejected_duplicate, rejected_plan_dup, rejected_soft,
            rejected_plan_cap, rejected_skeleton, rejected_near_dup)):
        print(
            f"[novelty control] rejected {rejected_invalid} invalid, "
            f"{rejected_duplicate} sql-duplicates, "
            f"{rejected_plan_dup} plan-duplicates, "
            f"{rejected_soft} soft-thinned, "
            f"{rejected_plan_cap} plan-capped, "
            f"{rejected_near_dup} near-duplicates, "
            f"{rejected_skeleton} skeleton-capped "
            f"({attempts} attempts for {len(accepted)} queries)"
        )

    return accepted


# ------------------------------------------------------------
# Workload writer (v3 layout + v4 provenance / soft-weighting config)
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
    soft_weight_strength: float = DEFAULT_SOFT_WEIGHT_STRENGTH,
) -> dict:
    """Same artefact layout as v3, tagged as v4 and documenting the H1 soft
    motif-weighting (plus the plan_shape mix carried over from v3)."""
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
                "changes the physical plan on the same selected tables (B)"
            ),
            "plan_motif_soft_weighting": (
                "H1: candidates accepted with probability 1/(1+strength*over), "
                "where 'over' is the mean usage of the candidate's operator "
                "trigrams relative to the current per-trigram average -- thins "
                f"over-represented plan motifs toward uniform (strength={soft_weight_strength})"
            ),
            "mixed_table_sampling": "coverage-weighted connected walk / connectivity-guaranteed uniform subset (E2ETune)",
            "coverage_aware_seeding": "1/(1+usage) table weighting (SQL-Factory Eq. 7, DiGiT)",
            "edge_aware_walk": "1/(1+edge usage) weighting toward under-covered FK edges (DiGiT gap filling)",
            "predicate_value_aid": "sampled live column values, weighted toward unused columns (E2ETune component 4)",
            "temperature_jitter": "per-family delta on base temperature (SQLStorm temp 1.0)",
            "novelty_control": (
                "A: EXPLAIN-derived plan-graph signature dedup + plan-family cap; "
                "H1: soft trigram-frequency down-weighting; layered on the v2 "
                "normalised-SQL dedup, skeleton cap, and (skeleton, table-set) "
                "near-duplicate rejection"
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
