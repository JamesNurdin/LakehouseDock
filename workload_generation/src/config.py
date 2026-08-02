"""
config -- the ONE place every hardcoded value lives, grouped by concept.

Rule: no magic numbers anywhere else in ``src/``. If a module needs a constant,
it imports it from here. Each value has a one-line rationale and its provenance
(the version it entered the lineage). Experiments override these by defining
their own ``EXP_*`` constants in ``experiments/<name>.py`` -- never by editing
this file.

Sections
  1. Environment / paths / model      (v1)
  2. LLM call behaviour               (v1, v2, v9)
  3. Concurrency / scheduling         (v6, v9.2, adaptive)
  4. Table / value sampling           (v1, v2)
  5. Prompt shape distribution        (v2, v3, v6)
  6. Acceptance / novelty caps        (v2, v3, v6)
  7. Operator-feedback (the loop)     (v8; supersedes v7.x)
"""

from __future__ import annotations

# Single source of truth for these currently lives in trino_stack.config; we
# re-export so src/ has one import surface. (Physically relocating them here is a
# follow-up -- update trino_stack.config importers at the same time.)
from trino_stack.config import (
    WORKLOAD_ROOT,      # where generated workloads are written
    SCHEMA_ROOT,        # where <schema>.json dataset definitions live
    MODEL_NAME,         # default model id (e.g. "gpt-oss-120b")
    BASE_MODEL_URL,     # default OpenAI-compatible endpoint
    API_KEY_ENV,        # env var name holding the API key
)

# ============================================================
# 1. Environment / paths / model  (v1)
# ============================================================
DEFAULT_REASONING = "high"       # reasoning effort; diversity comes from levers,
                                 # not reasoning depth, so this can often be lower

# ============================================================
# 2. LLM call behaviour  (v1 retry; v2 structured output; v9 token capture)
# ============================================================
REQUEST_TIMEOUT_S = 600.0        # per-call client timeout. This endpoint is
                                 # slow-but-serving; keep > the gateway's ~5min
                                 # timeout so patience collects slow completions.
RETRY_MAX_DEFAULT = 2000         # transient-error (503/504/timeout) retries.
                                 # Patient by design; the pool is NOT the backoff.
RETRY_SLEEP_S = 2.5              # fixed sleep between retries
WARMUP_RETRY_MAX = 16            # warmup uses exponential backoff instead
WARMUP_BASE_SLEEP_S = 10.0
WARMUP_MAX_SLEEP_S = 240.0
USE_RESPONSES_STREAMING = False  # stream Responses API (keeps long calls alive vs router 504s)
RETRY_VERBOSE = False            # print every transient-error retry (else the controller reports)

# ============================================================
# 3. Concurrency / scheduling  (v6 pool -> v9.2 continuous -> adaptive AIMD)
# ============================================================
GENERATION_WORKERS = 8           # DEFAULT in-flight ceiling. Treat as a ceiling,
                                 # not a fixed level. This endpoint degrades above
                                 # ~10-20 concurrent, so keep modest.
CONC_MIN = 2                     # AIMD floor: never throttle below this
CONC_START = 8                   # AIMD initial in-flight target (<= ceiling)
CONC_BETA = 0.5                  # AIMD multiplicative-decrease factor on contention
CONC_PROBE_INTERVAL_S = 12.0     # AIMD additive-increase (+1) cadence when healthy
CONC_COOLDOWN_S = 25.0           # after a cut: debounce further cuts + pause probing
MAX_ATTEMPT_FACTOR = 4.0         # attempt budget = MAX_ATTEMPT_FACTOR * num_queries (v3)

# ============================================================
# 4. Table / value sampling  (v1 walk; v2 coverage weighting + value aid)
# ============================================================
MIN_TABLES = 2
MAX_TABLES = 8
CONNECTED_FRACTION = 0.5         # fraction of draws that use the connected FK walk
                                 # vs a connectivity-guaranteed uniform subset

# ============================================================
# 5. Generation temperature
# ============================================================
TEMPERATURE = 0.6                # caller default (raised to the floor below)
TEMPERATURE_FLOOR = 0.9          # force SQLStorm-style hot sampling

# NOTE: the prompt VOCABULARY -- families, add-ons, plan-shapes and their weights
# / fire-probabilities / instruction lines -- lives inline in ``prompt.py`` (it's
# content, not tunable scalars). Edit prompt.py to change what goes into prompts.

# ============================================================
# 6. Acceptance / novelty caps  (v2 dedup; v3 plan-space; v6 stricter cap)
# ============================================================
SKELETON_CAP = 12                # max queries sharing one SQL skeleton (v2)
PLAN_SIGNATURE_CAP = 3           # max queries per plan family (v3=8 -> v6=3)

# ============================================================
# 7. Operator-feedback loop  (v8; the v7.x machinery is retired -- see feedback.py)
# ============================================================
NGRAM_N = 3                      # match the analyzer's Vendi n-gram order (reward unit)
HINT_SOFTMAX_TEMP = 0.5          # softmax temp over construct scores (lower = sharper toward the deficit)
CONDITIONAL_WEIGHT = 0.6         # down-weight of reliability=="conditional" constructs
ESC_WINDOW = 100                 # accepted-plan window for the discovery-plateau check
MAX_AGGRESSION = 3               # cap on extra constructs added per query when discovery plateaus

# Per-family construct budget (lo, hi): how many constructs the feedback policy
# draws per query. This is the primary lever on complexity vs invalid-rate --
# v8's unbudgeted stacking hit ~7 constructs/query and a 62% invalid rate; keep
# these small but non-trivial so motif variety (which drives Vendi) survives.
FAMILY_CONSTRUCT_BUDGET = {
    "simple":             (0, 0),
    "core_analytical":    (1, 3),
    "windows_ranking":    (1, 3),
    "nested_aggregation": (1, 3),
    "set_operations":     (1, 3),
    "multi_role_joins":   (2, 4),
    "string_regex":       (1, 2),
}

# Plumbing/surface operators excluded from STRUCTURAL motifs & steering (v72/v8).
# Coverage/entropy denominators use the reachable-structural set from
# operator_space; these are the ones the reward should not chase.
TRIVIAL_OPERATORS = frozenset({
    "Output", "RemoteSource", "LocalExchange", "RemoteExchange", "Exchange",
    "Project", "ScanFilterProject", "ScanFilter", "ScanProject", "TableScan",
    "Filter", "FilterProject", "Limit", "LimitPartial", "TopN", "TopNPartial",
    "TopNRanking", "DistinctLimit", "DistinctLimitPartial", "Sort", "LocalMerge",
    "RemoteMerge", "PartialSort", "AssignUniqueId", "Values",
})
