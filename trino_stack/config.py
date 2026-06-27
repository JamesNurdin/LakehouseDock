# trino/config.py

RELEASE_DEPLOY_TIMEOUT = 240 # s

# Connection defaults
TRINO_PORT = 8080
TRINO_USER = "admin"
TRINO_CATALOG = "iceberg"
TRINO_HTTP_SCHEME = "http"
TRINO_TIMEOUT = "30m"  

# Service naming
TRINO_SERVICE_PREFIX = "trino-service-"
TRINO_SERVICE_SUFFIX = ".svc.cluster.local"

# roots
WORKLOAD_ROOT = "/mnt/primary/Main/Workloads"
RESULTS_ROOT = "/mnt/lakehouse-raw-results" 


# Workload
LAKEHOUSE_SCHEMA = "tpcds"
WORKLOAD_NAME = "tpcds"
LOG_RESOURCES = False
RECORD_QUERY = True
RECORD_QUERY_PLAN = False

# Workload Generator
SCHEMA_ROOT = "/mnt/primary/Main/Datasets/schemas"
MODEL_NAME = "gpt-oss-120b"
BASE_MODEL_URL = "http://api.llm.apps.os.dcs.gla.ac.uk/v1"
API_KEY_ENV = "IDA_LLM_API_KEY"

# Node Logging 
LOGGING_PORT = 8099  