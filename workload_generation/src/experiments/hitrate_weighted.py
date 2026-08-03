"""
experiments/hitrate_weighted.py -- weight construct selection by REALISED landing rate.

Why
---
In the 109.6-Vendi run, ~10 of the 25 structural operators never landed
(FullOuterJoin, Union/Intersect/Except, CorrelatedJoin, Apply, Offset, Sample, ...)
even though their constructs fired heavily. Trino desugars/decorrelates/rewrites
them, so they never render as those operators. But coverage-need = 1/(1+usage)
keeps their usage pinned at 0 -> maximum need -> the budget keeps demanding
constructs that cannot land, wasting budget and driving invalids for zero coverage.

This policy multiplies each construct's score by a SMOOTHED landing rate so
constructs that don't materialise on THIS Trino get less budget -- WITHOUT ever
excluding them:

  p_land(c) = (hits_c + ALPHA) / (fires_c + ALPHA + BETA)     # Beta-Bernoulli
  p_land(c) = max(p_land(c), FLOOR)                           # exploration floor
  weight(c) = need(op) * reliability * p_land(c)

Two properties this buys us (both raised as concerns):
  * NO premature exclusion. p_land never hits 0 (prior + floor), so a construct
    that starts landing later -- landing is non-stationary; it depends on the
    sampled tables / predicates / randomness -- recovers on its own.
  * NO hardcoded reachability. Landing is measured against the DEPLOYED Trino, so
    it reflects whatever optimizer properties are set
    (optimizer.distinct-aggregations-strategy, push-aggregation-through-outer-join,
    ...). Change the engine config and the weighting re-learns; nothing is baked in.

Run
---
    from workload_generation.src import pipeline
    from workload_generation.src.experiments.hitrate_weighted import HitRateWeightedPolicy
    pipeline.generate_query_batch(..., policy=HitRateWeightedPolicy())

or, from the Lakehouse path, pass policy= through generate_workload if exposed;
otherwise set it as the default for an A/B run. A/B target: the 109.6-Vendi /
50%-invalid baseline -- expect lower invalids + budget redirected to constructs
that actually produce motifs.
"""

from __future__ import annotations

import random

from .. import config
from ..prompt import CONSTRUCTS
from ..feedback import FeedbackPolicy

# --- experiment knobs (namespaced EXP_*, not in config) ---
EXP_ALPHA = 1.0    # Beta prior "successes" (raise for a more optimistic cold start)
EXP_BETA = 1.0     # Beta prior "failures"
EXP_FLOOR = 0.05   # hard floor on p_land so no construct is ever fully excluded


class HitRateWeightedPolicy(FeedbackPolicy):
    """v8-family policy + realised-landing-rate weighting (never excludes)."""

    def choose_constructs(self, tracker, rng: random.Random, family: dict) -> list[dict]:
        fam = family["name"]
        lo, hi = config.FAMILY_CONSTRUCT_BUDGET.get(fam, (1, 2))
        if hi <= 0:
            return []

        fb = bool(getattr(tracker, "feedback_enabled", False))
        usage, aggression = tracker.feedback_state() if fb else ({}, 0)
        fires = dict(getattr(tracker, "hint_fires", {}))
        hits = dict(getattr(tracker, "hint_hits", {}))

        k = rng.randint(lo, hi) + (aggression if fb else 0)
        k = min(k, hi + config.MAX_AGGRESSION)

        candidates = [c for c in CONSTRUCTS if fam != "simple" or c.get("simple_ok")]
        scored = []
        for c in candidates:
            op = c.get("target_operator")
            need = (1.0 / (1.0 + usage.get(op, 0))) if (fb and op) else 1.0
            rel = 1.0 if c.get("reliability", "guaranteed") == "guaranteed" else config.CONDITIONAL_WEIGHT
            p_land = self._landing_rate(c["name"], op, fires, hits) if fb else 1.0
            scored.append((c, need * rel * p_land))

        chosen = self._sample_distinct(scored, k, rng)   # inherited softmax draw
        return [{"name": c["name"], "line": c["line"]} for c in chosen]

    @staticmethod
    def _landing_rate(name: str, target_operator, fires: dict, hits: dict) -> float:
        """Smoothed P(target operator lands | this construct fired). Pure-clause
        constructs (no target operator) always 'land' as intended shaping -> 1.0."""
        if target_operator is None:
            return 1.0
        f = fires.get(name, 0)
        h = hits.get(name, 0)
        p = (h + EXP_ALPHA) / (f + EXP_ALPHA + EXP_BETA)
        return max(p, EXP_FLOOR)
