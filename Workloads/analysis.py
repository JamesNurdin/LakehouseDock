"""
Standardised analysis for any workload directory (a folder of q*.sql files).

Two families of metrics feed into a single comparable row per workload:

  * Plan-based diversity metrics (schema/plan coverage, entropy, Vendi score,
    ...) computed by ``Lakehouse.workload_diversity_metrics`` over live Trino
    EXPLAIN plans. These require a connected ``lh`` (Lakehouse) instance.

  * Static SQL "metaheuristics" (table/join/aggregation counts, complexity
    mix, table-usage entropy, schema coverage, ...) as defined in
    ``query_gen_eval/sql_features.py``. Every baseline generator already
    writes these into ``generation_report.json``; if a workload has one, we
    read them straight from there. Otherwise (e.g. hand-written/imported
    workloads such as ``tpcds``) we compute them directly from the .sql
    files, so every workload ends up scored on the same axes.

Usage from the notebook::

    from Workloads.analysis import analyse_workload_set

    overview_df, failures_df = analyse_workload_set(
        WORKLOAD_NAMES,
        workload_root=WORKLOAD_ROOT,
        lh=lh,               # omit/None to skip the Trino plan metrics
        catalog="iceberg",
        schema="tpcds",
    )
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, Iterable, Optional, Tuple

import pandas as pd

from loader.stats import load_sql_workload
from query_gen_eval.sql_features import query_features, workload_metaheuristics
from trino_stack.config import WORKLOAD_ROOT as _DEFAULT_WORKLOAD_ROOT
from trino_stack.query_generator import extract_schema_tables, load_schema


# ---------------------------------------------------------------------------
# Path resolution
# ---------------------------------------------------------------------------

def resolve_workload_path(
    workload_name_or_path: str | Path,
    workload_root: str | Path = _DEFAULT_WORKLOAD_ROOT,
) -> Path:
    """
    Accept either:
      - a workload directory name, e.g. 'tpcds'
      - an absolute path, e.g. '/mnt/primary/Main/Workloads/tpcds'
    """
    path = Path(workload_name_or_path)

    if path.is_absolute():
        return path

    return Path(workload_root) / path


# ---------------------------------------------------------------------------
# Static SQL metaheuristics (generation_report.json, or computed fresh)
# ---------------------------------------------------------------------------

def load_generation_report(workload_dir: str | Path) -> Optional[dict]:
    """Read generation_report.json from a workload dir, if it exists."""
    path = Path(workload_dir) / "generation_report.json"
    if not path.exists():
        return None
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def compute_metaheuristics(
    workload_dir: str | Path,
    *,
    schema: Optional[str] = None,
    pattern: str = "q*.sql",
) -> dict:
    """
    Compute workload_metaheuristics(...) directly from the .sql files in
    workload_dir, for workloads that have no generation_report.json.

    ``schema`` (a schema name under trino_stack's SCHEMA_ROOT, e.g. "tpcds")
    is optional and only used for schema table-coverage; it does not require
    a live Trino connection.
    """
    workload = load_sql_workload(workload_dir, pattern=pattern)
    per_query = [
        query_features(record["sql"]) for record in workload["queries"].values()
    ]

    schema_tables = None
    if schema:
        schema_tables = extract_schema_tables(load_schema(schema))

    return workload_metaheuristics(per_query, schema_tables=schema_tables)


def get_workload_metaheuristics(
    workload_dir: str | Path,
    *,
    schema: Optional[str] = None,
    pattern: str = "q*.sql",
    force_recompute: bool = False,
) -> Tuple[dict, str]:
    """
    Return (metaheuristics, source), preferring a workload's own
    generation_report.json and falling back to computing them fresh.

    source is "generation_report" or "computed".
    """
    if not force_recompute:
        report = load_generation_report(workload_dir)
        if report and report.get("workload_metaheuristics"):
            return report["workload_metaheuristics"], "generation_report"

    return compute_metaheuristics(workload_dir, schema=schema, pattern=pattern), "computed"


def flatten_metaheuristics(meta: dict, *, prefix: str = "meta_") -> Dict[str, Any]:
    """Flatten a workload_metaheuristics(...) dict into scalar row columns."""
    row: Dict[str, Any] = {f"{prefix}num_queries": meta.get("num_queries")}

    for field, stats in (meta.get("distributions") or {}).items():
        for stat_name, value in (stats or {}).items():
            row[f"{prefix}{field}_{stat_name}"] = value

    n = meta.get("num_queries") or 0
    complexity_mix = meta.get("complexity_mix") or {}
    for level in ("low", "medium", "high"):
        count = complexity_mix.get(level, 0)
        row[f"{prefix}complexity_{level}_pct"] = round(100 * count / n, 2) if n else 0.0

    row[f"{prefix}table_usage_entropy"] = meta.get("table_usage_entropy")
    row[f"{prefix}unique_table_sets"] = meta.get("unique_table_sets")
    row[f"{prefix}unique_table_set_ratio"] = meta.get("unique_table_set_ratio")
    row[f"{prefix}unique_skeletons"] = meta.get("unique_skeletons")
    row[f"{prefix}unique_skeleton_ratio"] = meta.get("unique_skeleton_ratio")

    coverage = meta.get("schema_coverage")
    if coverage:
        row[f"{prefix}schema_table_coverage_pct"] = round(
            100 * coverage.get("table_coverage", 0.0), 2
        )

    row[f"{prefix}feature_extractor"] = meta.get("feature_extractor")
    return row


def metaheuristics_row(
    workload_dir: str | Path,
    *,
    schema: Optional[str] = None,
    pattern: str = "q*.sql",
    force_recompute: bool = False,
    prefix: str = "meta_",
) -> Dict[str, Any]:
    """One flattened metaheuristics row, tagged with where it came from."""
    meta, source = get_workload_metaheuristics(
        workload_dir,
        schema=schema,
        pattern=pattern,
        force_recompute=force_recompute,
    )
    row = flatten_metaheuristics(meta, prefix=prefix)
    row[f"{prefix}source"] = source
    return row


# ---------------------------------------------------------------------------
# Plan-based diversity metrics (requires a live Lakehouse)
# ---------------------------------------------------------------------------

def extract_plan_overview(out: Any) -> dict:
    """
    Extract the raw overview dict from lh.workload_diversity_metrics(...).

    Intentionally defensive, in case the wrapper returns slightly different
    structures.
    """
    if isinstance(out, dict):
        if "report" in out and isinstance(out["report"], dict):
            if "overview" in out["report"]:
                return out["report"]["overview"]

        if "overview" in out:
            return out["overview"]

    raise ValueError(
        "Could not find an overview dict in the workload_diversity_metrics output."
    )


# ---------------------------------------------------------------------------
# Standardised per-workload / multi-workload analysis
# ---------------------------------------------------------------------------

def analyse_workload(
    workload_name_or_path: str | Path,
    *,
    workload_root: str | Path = _DEFAULT_WORKLOAD_ROOT,
    lh=None,
    catalog: str = "iceberg",
    schema: str = "tpcds",
    metaheuristics_schema: Optional[str] = None,
    force_recompute_metaheuristics: bool = False,
) -> Dict[str, Any]:
    """
    One standardised row for a single workload directory, combining (when
    available) live Trino plan-diversity metrics with static SQL
    metaheuristics.

    Pass ``lh=None`` to skip the plan-based metrics entirely (useful for
    workloads/environments without a live Trino connection) -- the
    metaheuristics half still works on any directory of .sql files.
    """
    workload_path = resolve_workload_path(workload_name_or_path, workload_root)

    row: Dict[str, Any] = {
        "workload": workload_path.name,
        "workload_path": str(workload_path),
    }

    if lh is not None:
        plan_bundle = lh.load_query_plans(workload_path=str(workload_path), schema=schema)
        out = lh.workload_diversity_metrics(plan_bundle, catalog=catalog, schema=schema)
        overview = extract_plan_overview(out)

        row["workload"] = plan_bundle.get("workload_name", workload_path.name)
        row["query_count"] = plan_bundle.get("query_count")
        row["ok"] = plan_bundle.get("ok")
        row["failed"] = plan_bundle.get("failed")
        row.update(overview)

    row.update(
        metaheuristics_row(
            workload_path,
            schema=metaheuristics_schema or schema,
            force_recompute=force_recompute_metaheuristics,
        )
    )

    return row


def analyse_workload_set(
    workload_names: Iterable[str | Path],
    *,
    workload_root: str | Path = _DEFAULT_WORKLOAD_ROOT,
    lh=None,
    catalog: str = "iceberg",
    schema: str = "tpcds",
    metaheuristics_schema: Optional[str] = None,
    force_recompute_metaheuristics: bool = False,
) -> Tuple[pd.DataFrame, pd.DataFrame]:
    """
    Standardised overview-metric table for multiple workloads: one row per
    workload, columns are plan-diversity metrics (if ``lh`` is given) plus
    "meta_"-prefixed static SQL metaheuristics.
    """
    rows = []
    failures = []

    for workload_name in workload_names:
        workload_path = resolve_workload_path(workload_name, workload_root)
        print(f"\n=== Analysing workload: {workload_path.name} ===")

        try:
            rows.append(
                analyse_workload(
                    workload_name,
                    workload_root=workload_root,
                    lh=lh,
                    catalog=catalog,
                    schema=schema,
                    metaheuristics_schema=metaheuristics_schema,
                    force_recompute_metaheuristics=force_recompute_metaheuristics,
                )
            )
        except Exception as e:
            failures.append({
                "workload": workload_path.name,
                "workload_path": str(workload_path),
                "error": repr(e),
            })
            print(f"FAILED: {workload_path.name}")
            print(repr(e))

    metrics_df = pd.DataFrame(rows)

    if not metrics_df.empty:
        front_cols = [
            c for c in ["workload", "workload_path", "query_count", "ok", "failed"]
            if c in metrics_df.columns
        ]
        metric_cols = [c for c in metrics_df.columns if c not in front_cols]
        metrics_df = metrics_df[front_cols + metric_cols]

    failures_df = pd.DataFrame(failures)

    return metrics_df, failures_df
