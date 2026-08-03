"""
experiments/entropy_boost.py -- push SCHEMA entropy (free) and, optionally, operator
n-gram entropy via query-size variety (costs some Vendi).

Two INDEPENDENT toggles:

  schema_entropy (no Vendi cost)
    Steepen the coverage weighting (1/(1+usage) -> 1/(1+usage)**POWER) so over-used
    tables/edges/columns are penalised harder -> flatter usage -> higher
    table/column/join-edge entropy. Also show more under-used columns in the value
    aid. Doesn't touch query complexity, so Vendi is unaffected.

  size_variety (trades Vendi for flatter operator/3-gram entropy)
    Rebalance family weights toward MORE small + MORE deep queries (bimodal). A wide
    size spread flattens the operator/motif count distribution (fewer medium plans
    all repeating the same InnerJoin/Aggregate plumbing), raising operator_ngram
    entropy -- but small plans add fewer motifs, so expect some Vendi cost.

These levers live in sampling/prompt, which are NOT policy-injectable, so this file
mutates ``config`` + ``prompt.PROMPT_VARIANTS`` globals and hands back a ``revert()``.
The core defaults (POWER=1.0, MAX_COLS=8, baseline family weights) are unchanged, so
without ``activate()`` nothing differs.

    from workload_generation.src.experiments import entropy_boost
    revert = entropy_boost.activate(schema_entropy=True, size_variety=False)
    lh.generate_workload(schema="tpcds", workload_name="gpt_generated_1000_tpcds_entropy", ...)
    revert()

Suggested A/B: schema_entropy alone first (should raise column ~0.89->0.92 and
join-edge ~0.92->0.95 with Vendi ~unchanged); then add size_variety and read the
operator_ngram_entropy vs Vendi trade.
"""

from __future__ import annotations

from .. import config
from .. import prompt

# --- experiment knobs (namespaced EXP_*) ---
EXP_COVERAGE_POWER = 1.8       # >1 flattens table/edge/column usage
EXP_VALUE_AID_MAX_COLS = 14    # show more under-used columns (was 8)

# Size-variety family weights (MUST sum to 1.0): more simple + more multi_role,
# less medium, than the baseline (simple 0.10, core 0.20, ...).
EXP_FAMILY_WEIGHTS = {
    "simple":             0.22,
    "core_analytical":    0.16,
    "windows_ranking":    0.12,
    "nested_aggregation": 0.10,
    "set_operations":     0.14,
    "multi_role_joins":   0.16,
    "string_regex":       0.10,
}


def activate(*, schema_entropy: bool = True, size_variety: bool = False):
    """Apply the selected toggles by mutating globals. Returns a ``revert()`` that
    restores the originals -- call it after the run for a clean A/B."""
    saved = {
        "power": config.COVERAGE_WEIGHT_POWER,
        "cols": config.VALUE_AID_MAX_COLS,
        "weights": [v["weight"] for v in prompt.PROMPT_VARIANTS],
    }

    if schema_entropy:
        config.COVERAGE_WEIGHT_POWER = EXP_COVERAGE_POWER
        config.VALUE_AID_MAX_COLS = EXP_VALUE_AID_MAX_COLS

    if size_variety:
        s = sum(EXP_FAMILY_WEIGHTS.values())
        if abs(s - 1.0) > 1e-6:
            raise ValueError(f"EXP_FAMILY_WEIGHTS must sum to 1.0 (got {s})")
        for v in prompt.PROMPT_VARIANTS:
            v["weight"] = EXP_FAMILY_WEIGHTS.get(v["name"], v["weight"])

    def revert():
        config.COVERAGE_WEIGHT_POWER = saved["power"]
        config.VALUE_AID_MAX_COLS = saved["cols"]
        for v, w in zip(prompt.PROMPT_VARIANTS, saved["weights"]):
            v["weight"] = w

    return revert
