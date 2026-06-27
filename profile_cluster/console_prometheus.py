import requests
import urllib3
from datetime import datetime, timezone, timedelta

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


# ---------------------------------------------------------------------
# Hardcoded OpenShift console Prometheus settings
# ---------------------------------------------------------------------

PROM_URL = "https://console-openshift-console.apps.os.dcs.gla.ac.uk/api/prometheus/api/v1"


def clean_cookie(raw_cookie: str) -> str:
    """
    Allows pasting either:
      - the full DevTools block beginning with 'Cookie'
      - or just the cookie value itself.
    """
    cookie = raw_cookie.strip()

    if cookie.lower().startswith("cookie"):
        cookie = cookie.split("\n", 1)[1].strip()

    return " ".join(cookie.split())


# ---------------------------------------------------------------------
# Prometheus API helpers
# ---------------------------------------------------------------------

def prom_query(query: str, headers) -> dict:
    """
    Run an instant PromQL query.
    """
    response = requests.get(
        f"{PROM_URL}/query",
        headers=headers,
        params={"query": query},
        verify=False,
        timeout=30,
    )

    response.raise_for_status()
    data = response.json()

    if data.get("status") != "success":
        raise RuntimeError(f"Prometheus query failed: {data}")

    return data


def prom_query_range(
    query: str,
    start: str,
    end: str,
    headers,
    step: str = "10s",
) -> dict:
    """
    Run a PromQL range query.

    start/end should be RFC3339 timestamps, e.g.
    2026-05-06T10:00:00Z
    """
    response = requests.get(
        f"{PROM_URL}/query_range",
        headers=headers,
        params={
            "query": query,
            "start": start,
            "end": end,
            "step": step,
        },
        verify=False,
        timeout=60,
    )

    response.raise_for_status()
    data = response.json()

    if data.get("status") != "success":
        raise RuntimeError(f"Prometheus range query failed: {data}")

    return data


# ---------------------------------------------------------------------
# Example queries
# ---------------------------------------------------------------------

def trino_cpu_query(namespace: str) -> str:
    return f'''
sum by(pod,container) (
  rate(container_cpu_usage_seconds_total{{
    namespace="{namespace}",
    pod=~"trino.*",
    container=~"trino-worker|trino-coord"
  }}[5m])
)
'''.strip()


def trino_memory_query(namespace: str) -> str:
    return f'''
sum by(pod,container) (
  container_memory_working_set_bytes{{
    namespace="{namespace}",
    pod=~"trino.*",
    container=~"trino-worker|trino-coord"
  }}
)
'''.strip()


def print_instant_results(data: dict) -> None:
    for result in data["data"]["result"]:
        metric = result["metric"]
        timestamp, value = result["value"]

        pod = metric.get("pod", "")
        container = metric.get("container", "")
        print(f"{pod}\t{container}\t{timestamp}\t{value}")


