# config.py
from pathlib import Path

# Root
PARSED_ROOT = Path("/mnt/primary/Main/Parsed_Results")
RESULTS_ROOT = Path("/mnt/lakehouse-raw-results") # Dont use the symlink for this, the overview files point to the actual mounted path

# -----------------
# Staging
# -----------------
COLLECTION_NAME = "tpcds_500"
SCHEMA_NAME = "tpcds"
LAKEHOUSE_INSTANCE_NAME = "lakehouse-a"

RUN_IDS = [
    "20260222-191819Z",
    "20260223-161227Z",
    "20260224-125456Z",
    "20260225-095819Z",
    "20260226-065736Z",
]



# -----------------
# Aggregating Traces From workers
# -----------------
DEFAULT_CORES_PER_WORKER = 48
WORKER_CORE_MAP = {}
NODE_GLOB = "trino-worker-*_metrics.csv"
GRID_POINTS = 400

# -------------------------
# CSV schema (fixed)
# -------------------------
TIME_COL = "epoch_ms"             # milliseconds since epoch
CPU_COUNTER = "process_cpu_s"     # counter (seconds)
IDLE_COUNTER = "node_cpu_idle_s"  # counter (seconds) [not required for util%]
MEM_GAUGE = "trino_mem_bytes"     # gauge (bytes)
READ_COUNTER = "trino_read_bytes" # counter (bytes)
TX_COUNTER = "http_sent_bytes"    # counter (bytes)
RX_COUNTER = "http_recv_bytes"    # counter (bytes)

QID_COL = "trino_query_id"
ATTEMPT_COL = "attempt"
QNAME_COL = "query_name"

REQUIRED_COLS = [
    TIME_COL, CPU_COUNTER, MEM_GAUGE, READ_COUNTER, TX_COUNTER, RX_COUNTER,
    QID_COL, ATTEMPT_COL, QNAME_COL
]

ALSO_STAGE_COORD = True
COORD_METRICS_GLOB = "trino-coord-pod-*_metrics.csv"

# -------------------------
# Parsing toggles
# -------------------------
PARSE_METRICS = True
PARSE_PROFILES = True
ALLOW_PROFILE_ONLY_RUNS = True

# -------------------------
# Node profiler snapshots
# -------------------------
PROFILE_DIR_NAME = "profiles"
PROFILE_GLOB = "*_node_profiles.csv"
PROFILE_OUTPUT_NAME = "node_profiles.csv"


# Staging behaviour
STAGE_MODE = "copy"   # or "symlink"