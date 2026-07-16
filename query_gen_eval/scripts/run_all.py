"""
Run every baseline across one or more schemas for a full comparison sweep.

Produces one workload directory per (baseline, schema) plus a top-level
``comparison_summary.json`` collecting each run's workload metaheuristics so
the QueryDock generator and all baselines can be compared side by side.

Example (from the LakehouseDock control container / notebook kernel):

    python -m query_gen_eval.scripts.run_all \
        --schemas tpcds ssb imdb \
        --instance lakehouse-a --namespace pgr24james \
        --num-queries 1000

Add ``--baselines sqlstorm e2etune`` to restrict the set.
"""

from __future__ import annotations

import argparse
import json
import sys
import traceback
from datetime import datetime, timezone
from pathlib import Path

from query_gen_eval.common import context_from_factories, context_from_lakehouse
from query_gen_eval.baselines import BASELINES


def _context_builder(args, schema):
    from trino_stack.config import MODEL_NAME, BASE_MODEL_URL, API_KEY_ENV

    kwargs = dict(
        schema=schema, catalog=args.catalog,
        model_name=args.model_name or MODEL_NAME,
        base_url=args.base_url or BASE_MODEL_URL,
        api_key_env=args.api_key_env or API_KEY_ENV,
        temperature=args.temperature, reasoning=args.reasoning,
    )
    if args.instance:
        from trino_stack.lakehouse import Lakehouse
        lh = Lakehouse.from_release(instance_name=args.instance,
                                    namespace=args.namespace,
                                    sync_schemas=False, verbose=args.verbose)
        return context_from_lakehouse(lh, **kwargs)
    if args.trino_host:
        from trino_stack import hive as hive_mod

        def conn_factory():
            return hive_mod.connect_trino(args.trino_host, schema)
        return context_from_factories(conn_factory=conn_factory, **kwargs)
    raise SystemExit("Provide either --instance or --trino-host")


def main(argv=None):
    p = argparse.ArgumentParser(description="Run all baselines across schemas.")
    p.add_argument("--schemas", nargs="+", required=True)
    p.add_argument("--baselines", nargs="+", default=sorted(BASELINES),
                   choices=sorted(BASELINES))
    p.add_argument("--num-queries", type=int, default=1000)
    p.add_argument("--catalog", default="iceberg")
    p.add_argument("--instance", default=None)
    p.add_argument("--namespace", default="pgr24james")
    p.add_argument("--trino-host", default=None)
    p.add_argument("--model-name", default=None)
    p.add_argument("--base-url", default=None)
    p.add_argument("--api-key-env", default=None)
    p.add_argument("--temperature", type=float, default=0.6)
    p.add_argument("--reasoning", default="medium")
    p.add_argument("--workload-root", default=None)
    p.add_argument("--random-seed", type=int, default=None)
    p.add_argument("--no-warmup", action="store_true")
    p.add_argument("--verbose", action="store_true")
    p.add_argument("--summary-out", default=None,
                   help="path for comparison_summary.json (default: <workload-root>/comparison_summary.json)")
    args = p.parse_args(argv)

    summary = {"created_at_utc": datetime.now(timezone.utc).isoformat(),
               "num_queries": args.num_queries, "runs": []}

    for schema in args.schemas:
        ctx = _context_builder(args, schema)
        warmed = False
        for baseline in args.baselines:
            name = f"{baseline}_{schema}"
            print(f"\n=== {baseline} on {schema} -> {name} ===")
            kwargs = dict(workload_name=name, num_queries=args.num_queries,
                          warmup=(not args.no_warmup) and (not warmed),
                          random_seed=args.random_seed)
            if args.workload_root:
                kwargs["workload_root"] = args.workload_root
            try:
                report = BASELINES[baseline](ctx, **kwargs)
                warmed = True
                summary["runs"].append({
                    "baseline": baseline, "schema": schema,
                    "workload_name": name, "workload_dir": report["workload_dir"],
                    "num_queries": report["num_queries"],
                    "duration_s": report["duration_s"],
                    "workload_metaheuristics": report["workload_metaheuristics"],
                })
            except Exception as e:
                print(f"[run_all] {baseline}/{schema} FAILED: {e}")
                traceback.print_exc()
                summary["runs"].append({"baseline": baseline, "schema": schema,
                                        "workload_name": name, "error": str(e)})

    out = args.summary_out
    if out is None:
        from trino_stack.config import WORKLOAD_ROOT
        root = Path(args.workload_root or WORKLOAD_ROOT)
        out = str(root / "comparison_summary.json")
    Path(out).write_text(json.dumps(summary, indent=2, default=str), encoding="utf-8")
    print(f"\n[run_all] wrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
