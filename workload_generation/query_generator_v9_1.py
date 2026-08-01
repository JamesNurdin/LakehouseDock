"""
query_generator_v9_1 -- dose-corrected validity gate (refines v9).

Why refine v9
-------------
v9 fixed the failure spike (candidate invalid rate 62% -> 29%) but UNDER-DOSED
the deficit hints: 65% of candidates got zero hints and 88% got <=1, versus v8's
forced ~4-5. Fewer operator hints -> fewer forced rare operators -> fewer novel
plan-graph 3-grams -> plan-graph Vendi fell 114 (v8) -> 92 (v9). The gate did
exactly what it was told; the policy was just too conservative for a
diversity-max objective. Root causes (from the v9 per-depth accounting):

  * depth-0 was 65% of candidates -- pure wasted diversity (no operator pressure);
  * continuation-prob = ABSOLUTE validity is geometrically self-limiting and
    also throttles on the ~21% baseline generation-noise at depth 0.

v9_1 keeps ALL of v9 (operator grounding, Thompson learning, per-candidate
token/validity accounting) and changes ONLY the depth policy in
``sample_hint_set``:

  A (forced first lever).  Every non-``simple`` query gets at least
     ``V91_MIN_HINTS`` hint(s) with NO gate -- the depth-0 bucket disappears and
     the dose ~doubles at only the cheap depth-1 validity cost. Because the first
     lever is unconditional, the gate no longer reacts to depth-0 baseline noise.

  C (threshold gate for deeper levels).  Beyond the forced floor, continue
     k -> k+1 only while the (Thompson-sampled) validity at k+1 clears a
     threshold ``V91_VALIDITY_TAU``; between tau and 1.0 the continuation
     probability ramps up to ``V91_CONT_CEILING``. This is a "stop only at the
     cliff" brake, not a validity-proportional throttle -- moderate-validity
     depths are no longer strangled, but a genuinely failing depth still closes.

Not attempted here (deferred to a v9_2): per-lever / pairwise attribution (fix
D) -- keep depth high while avoiding the specific FRAGILE levers. That is the
path to fully match v8's Vendi without inheriting its failure rate; v9_1 aims
for the better operating point (~100-105 Vendi at a respectable validity).

``feedback_enabled=False`` -> no hints == v6, exactly as v9.
"""

from __future__ import annotations

import math
import random

import workload_generation.query_generator_v9 as _v9
from workload_generation.query_generator_v9 import (
    load_schema,
    make_openai_client,
    warm_up_model,
    fetch_table_columns,
    fetch_schema_table_columns,
    generate_query,
    generate_query_batch,
    DiversityTrackerV9,
    V9_MAX_DEPTH,
    V9_SOFTMAX_TEMP,
    V9_CONDITIONAL_WEIGHT,
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
    "DiversityTrackerV91",
]

GENERATOR_VERSION = "query_generator_v9_1"

# ---- v9_1 depth-policy tunables ----
# NOTE on calibration: the observed v9 per-depth validity was ~{1:0.64, 2:0.41,
# 3:0.55}. tau MUST sit clearly BELOW the depth-2 validity (~0.41), or fix C
# lands on the cliff and slams depth 2 shut -> a spike at depth 1 (no better than
# v9). tau=0.25 lets depth 2-3 open while still closing the real depth-4/5 cliff.
# To chase a bigger (v8-like) dose, raise V91_MIN_HINTS to 2 -- but expect
# candidate validity to fall to ~0.45 (i.e. re-approach v8's failure rate). That
# is the validity/diversity dial; fix D (per-lever attribution, v9_2) is the way
# to raise the dose WITHOUT paying that validity cost.
V91_MIN_HINTS = 1          # A: forced hints (no gate) on every non-simple query
V91_VALIDITY_TAU = 0.25    # C: validity below this -> stop opening deeper
V91_CONT_CEILING = 0.90    # C: max continuation prob when validity is healthy


class DiversityTrackerV91(DiversityTrackerV9):
    """v9 tracker with the depth policy replaced by fix A (forced first lever) +
    fix C (threshold gate). All v9 learning/accounting state is inherited."""

    def sample_hint_set(self, rng: random.Random, *, family_name: str) -> list[dict]:
        if not self.feedback_enabled or not self._hint_candidates:
            return []
        if family_name == "simple":                  # keep the simple family simple
            return []

        with self.lock:
            usage = dict(self.operator_usage)
            alpha = list(self.depth_alpha)
            beta = list(self.depth_beta)
            div = [self._diversity_brake_locked(d) for d in range(len(alpha))]

        # deficit scores (need * reliability) -- selection is unchanged from v9.
        scored = []
        for lv in self._hint_candidates:
            need = 1.0 / (1.0 + usage.get(lv.target_operator, 0))
            rel = 1.0 if lv.reliability == "guaranteed" else V9_CONDITIONAL_WEIGHT
            scored.append((lv, need * rel))

        chosen, used_ops = [], set()
        k = 0
        while k < V9_MAX_DEPTH:
            nxt = k + 1
            if k < V91_MIN_HINTS:
                open_gate = True                     # A: forced, ungated floor
            else:
                # C: Thompson-sampled validity, thresholded ramp (not proportional).
                v = rng.betavariate(alpha[nxt], beta[nxt])
                ramp = (v - V91_VALIDITY_TAU) / max(1e-9, 1.0 - V91_VALIDITY_TAU)
                ramp = min(1.0, max(0.0, ramp))
                p_cont = V91_CONT_CEILING * ramp * div[nxt]
                open_gate = rng.random() < p_cont
            if not open_gate:
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


_DEFAULT_TRACKER_V91 = DiversityTrackerV91()


def write_workload_directory(**kwargs):
    """v9's writer (per-query tokens + generation accounting), retagged v9_1 with
    the fix-A/C policy knobs recorded in ``plan_feedback``."""
    return _v9.write_workload_directory(
        generator_version=GENERATOR_VERSION,
        feedback_overrides={
            "mechanism": (
                "dose-corrected validity gate: forced first lever (A) + "
                "threshold-gated deeper levels (C) + Vendi-aligned 3-gram reward"
            ),
            "depth_policy": (
                f"forced >= {V91_MIN_HINTS} hint(s); beyond that continue only "
                f"while Thompson(validity@k+1) > tau={V91_VALIDITY_TAU}, ramping "
                f"to ceiling={V91_CONT_CEILING}"
            ),
            "min_hints_forced": V91_MIN_HINTS,
            "validity_tau": V91_VALIDITY_TAU,
            "continuation_ceiling": V91_CONT_CEILING,
        },
        **kwargs,
    )
