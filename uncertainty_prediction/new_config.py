# config.py
from pathlib import Path

# -----------------
# Query Trace Path
# -----------------

PARSED_RESULTS_ROOT = "/mnt/primary/Main/Parsed_Results"

COLLECTION_NAME = "tpcds_500_new"
SCHEMA_NAME = "tpcds"
LAKEHOUSE_INSTANCE_NAME = "lakehouse-a"
RUN_IDS = ["20260429-135222Z",
           "20260430-153315Z",
           "20260501-174214Z"]

# -----------------
# Workload Metric
# -----------------
METRIC = "cpu_cores"
XCOL = "t_rel_s"
YCOL = "value"

SEED = 42
TEST_FRAC = 0.2
