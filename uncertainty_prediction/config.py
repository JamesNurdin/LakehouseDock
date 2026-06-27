# config.py
from pathlib import Path

# -----------------
# Query Trace Path
# -----------------

PARSED_RESULTS_ROOT = "/mnt/primary/Main/Parsed_Results"

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
# Workload Metric
# -----------------
METRIC = "cpu_cores"
XCOL = "t_rel_s"
YCOL = "value"

SEED = 42
TEST_FRAC = 0.2