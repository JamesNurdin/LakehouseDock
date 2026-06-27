from __future__ import annotations

import time
from pathlib import Path
from datetime import datetime, timezone

import yaml

from kubernetes_helpers import (
    k8s_dynamic_client,
    apply_manifests,
    delete_object,
)



# ---------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------

MANIFEST_PATH = Path("./daemonset.yaml")
NAMESPACE = "pgr24james"

RUN_FOR_SECONDS = 5 * 60       # 5 minutes
PAUSE_FOR_SECONDS = 15 * 60    # 30 minutes

# If your manifest name changes, update this
DAEMONSET_NAME = "node-profiler"


def load_manifests(path: Path) -> list[dict]:
    if not path.exists():
        raise FileNotFoundError(f"Manifest file not found: {path.resolve()}")

    with path.open("r", encoding="utf-8") as f:
        docs = [doc for doc in yaml.safe_load_all(f) if doc is not None]

    if not docs:
        raise ValueError(f"No manifests found in {path.resolve()}")

    return docs

def inject_cycle_timestamp(manifests: list[dict]) -> list[dict]:
    cycle_ts = datetime.now(timezone.utc).isoformat(timespec="seconds")

    for manifest in manifests:
        if manifest.get("apiVersion") == "apps/v1" and manifest.get("kind") == "DaemonSet":
            containers = manifest["spec"]["template"]["spec"]["containers"]
            for container in containers:
                env = container.setdefault("env", [])

                replaced = False
                for item in env:
                    if item.get("name") == "PROFILE_LAUNCHED_AT":
                        item["value"] = cycle_ts
                        replaced = True
                        break

                if not replaced:
                    env.append({
                        "name": "PROFILE_LAUNCHED_AT",
                        "value": cycle_ts,
                    })

    return manifests


def main() -> None:
    dyn = k8s_dynamic_client()

    cycle = 0
    while True:
        cycle += 1
        print(f"\n=== Cycle {cycle}: applying DaemonSet ===")
        
        manifests = load_manifests(MANIFEST_PATH)
        manifests = inject_cycle_timestamp(manifests)

        applied = apply_manifests(
            manifests=manifests,
            namespace=NAMESPACE,
            dyn=dyn,
            field_manager="python-deployer",
        )
        print(f"Applied {applied} manifest(s). Sleeping for {RUN_FOR_SECONDS} seconds...")
        time.sleep(RUN_FOR_SECONDS)

        print(f"=== Cycle {cycle}: deleting DaemonSet '{DAEMONSET_NAME}' ===")
        deleted = delete_object(
            dyn=dyn,
            api_version="apps/v1",
            kind="DaemonSet",
            name=DAEMONSET_NAME,
            namespace=NAMESPACE,
            grace_period_seconds=0,
            propagation_policy="Background",
        )

        if deleted:
            print("Delete issued successfully.")
        else:
            print("DaemonSet not found at delete time.")

        print(f"Sleeping for {PAUSE_FOR_SECONDS} seconds before next cycle...")
        time.sleep(PAUSE_FOR_SECONDS)


if __name__ == "__main__":
    main()