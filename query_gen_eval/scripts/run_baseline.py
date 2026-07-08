"""
Run a single related-work baseline against a deployed lakehouse.

Two ways to provide a Trino connection + LLM client:

  A) Live Lakehouse (matches launch_lakehouse.ipynb) -- default:

        python -m query_gen_eval.scripts.run_baseline \
            --baseline sqlstorm --schema tpcds \
            --instance lakehouse-a --namespace pgr24james \
            --num-queries 100 --workload-name sqlstorm_tpcds

  B) Raw Trino host (no kubernetes), e.g. from inside the control container:

        python -m query_gen_eval.scripts.run_baseline \
            --baseline e2etune --schema tpcds \
            --trino-host trino-service-lakehouse-a.pgr24james.svc.cluster.local \
            --num-queries 100

The generated workload directory (``q<i>.sql`` + ``generation_report.json``)
is written under ``WORKLOAD_ROOT`` (or ``--workload-root``), exactly like
``Lakehouse.generate_workload``.
"""

from __future__ import annotations

import argparse
import json
import sys

import query_gen_eval._bootstrap  # noqa: F401
from query_gen_eval.common import context_from_factories, context_from_lakehouse
from query_gen_eval.baselines import BASELINES


def _build_context(args):
    from trino_stack.config import MODEL_NAME, BASE_MODEL_URL, API_KEY_ENV

    common_kwargs = dict(
        schema=args.schema,
        catalog=args.catalog,
        model_name=args.model_name or MODEL_NAME,
        base_url=args.base_url or BASE_MODEL_URL,
        api_key_env=args.api_key_env or API_KEY_ENV,
        temperature=args.temperature,
        reasoning=args.reasoning,
    )

    if args.instance:
        from trino_stack.lakehouse import Lakehouse
        lh = Lakehouse.from_release(
            instance_name=args.instance,
            namespace=args.namespace,
            sync_schemas=False,
            verbose=args.verbose,
        )
        return context_from_lakehouse(lh, **common_kwargs)

    if args.trino_host:
        from trino_stack import hive as hive_mod

        def conn_factory():
            return hive_mod.connect_trino(args.trino_host, args.schema)

        return context_from_factories(conn_factory=conn_factory, **common_kwargs)

    raise SystemExit("Provide either --instance (+ --namespace) or --trino-host")


def main(argv=None):
    p = argparse.ArgumentParser(description="Run a related-work SQL-gen baseline.")
    p.add_argument("--baseline", required=True, choices=sorted(BASELINES),
                   help="which baseline to run")
    p.add_argument("--schema", required=True, help="lakehouse schema (e.g. tpcds)")
    p.add_argument("--workload-name", default=None,
                   help="output workload dir name (default: <baseline>_<schema>)")
    p.add_argument("--num-queries", type=int, default=100)
    p.add_argument("--catalog", default="iceberg")

    # connection: A) lakehouse instance
    p.add_argument("--instance", default=None, help="Lakehouse release instance name")
    p.add_argument("--namespace", default="pgr24james")
    # connection: B) raw trino host
    p.add_argument("--trino-host", default=None)

    # model
    p.add_argument("--model-name", default=None)
    p.add_argument("--base-url", default=None)
    p.add_argument("--api-key-env", default=None)
    p.add_argument("--temperature", type=float, default=0.6)
    p.add_argument("--reasoning", default="medium")

    p.add_argument("--workload-root", default=None)
    p.add_argument("--random-seed", type=int, default=None)
    p.add_argument("--no-warmup", action="store_true")
    p.add_argument("--verbose", action="store_true")
    # arbitrary baseline kwargs as JSON, e.g. --extra '{"rewrite_pass": false}'
    p.add_argument("--extra", default=None,
                   help="JSON dict of extra kwargs forwarded to the baseline")
    args = p.parse_args(argv)

    ctx = _build_context(args)
    workload_name = args.workload_name or f"{args.baseline}_{args.schema}"

    kwargs = dict(
        workload_name=workload_name,
        num_queries=args.num_queries,
        warmup=not args.no_warmup,
        random_seed=args.random_seed,
    )
    if args.workload_root:
        kwargs["workload_root"] = args.workload_root
    if args.extra:
        kwargs.update(json.loads(args.extra))

    fn = BASELINES[args.baseline]
    print(f"[run_baseline] {args.baseline} -> {workload_name} "
          f"({args.num_queries} queries, schema={args.schema})")
    report = fn(ctx, **kwargs)

    print(json.dumps({
        "baseline": report["baseline"],
        "workload_dir": report["workload_dir"],
        "num_queries": report["num_queries"],
        "duration_s": round(report["duration_s"], 1),
        "workload_metaheuristics": report["workload_metaheuristics"],
    }, indent=2, default=str))
    return 0


if __name__ == "__main__":
    sys.exit(main())
