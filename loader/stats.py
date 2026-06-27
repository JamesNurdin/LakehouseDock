import json
import re

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

from collections import Counter
from typing import Dict, Any, Iterable, Tuple, Optional, List, Union, Iterator
from pathlib import Path

from loader.parser import build_trino_dag, iter_edges
from loader.load import iter_trino_dags_with_id, iter_workload_log_records
        
def extract_query_runtimes_s(
    workload_log_path: Union[str, Path],
    *,
    prefer: Tuple[str, ...] = ("runtime_s", "runtime_sec", "runtimeSeconds", "duration_s"),
    query_key_candidates: Tuple[str, ...] = ("query_name", "query", "qid", "name"),
    keep_last: bool = True,
) -> Dict[str, float]:
    """
    Extract per-query runtime (seconds) from workload_log.ndjson.

    Returns
    -------
    dict[str, float]
        Mapping { "q1": 12.34, "q2": 0.98, ... }.

    Notes
    -----
    - Uses `prefer` to find runtime field names.
    - Uses `query_key_candidates` to find the per-query identifier.
    - If the same query appears multiple times, keeps the last record by default
      (set keep_last=False to keep the first).
    """
    runtimes: Dict[str, float] = {}

    for rec in iter_workload_log_records(workload_log_path):
        # find query name
        qname: Optional[str] = None
        for k in query_key_candidates:
            if k in rec and rec[k] is not None:
                qname = str(rec[k]).strip()
                break
        if not qname:
            continue

        # normalize to prefix-only qX if the log has extra suffixes
        # examples handled: "q1", "q1_001", "q1 (something)", "q1_explain"
        # we keep only the leading "q<digits>"
        import re
        m = re.match(r"^(q\d+)\b", qname)
        if m:
            qname = m.group(1)

        # find runtime
        rt = None
        for k in prefer:
            if k in rec and rec[k] is not None:
                rt = rec[k]
                break
        if rt is None:
            continue

        # coerce to float
        try:
            rt_f = float(rt)
        except (TypeError, ValueError):
            continue

        if (qname not in runtimes) or keep_last:
            runtimes[qname] = rt_f

    return runtimes
        
def count_remote_edges(dag: Dict[str, Any]) -> int:
    """Count cross-fragment edges (etype == 'remote')."""
    n = 0
    for src, dst, etype in iter_edges(dag):
        if str(etype).lower() == "remote":
            n += 1
    return n


def count_remote_sources(dag: Dict[str, Any]) -> int:
    """Alternative proxy: count RemoteSource operators."""
    return sum(
        1 for nid, attrs in dag.get("nodes", {}).items()
        if str(attrs.get("name", "")).lower() == "remotesource".lower()
    )

def build_remote_vs_runtime_df(
    *,
    queries_dir: str | Path,
    workload_log_path: str | Path,
    remote_metric: str = "remote_edges",  # or "remote_sources"
):
    """
    Returns df with columns:
      - query
      - remote_exchanges
      - runtime_s
    """
    runtimes = extract_query_runtimes_s(workload_log_path)

    rows = []
    for qid, dag in iter_trino_dags_with_id(queries_dir):
        if qid not in runtimes:
            continue

        if remote_metric == "remote_sources":
            r = count_remote_sources(dag)
        else:
            r = count_remote_edges(dag)

        rows.append({
            "query": qid,
            "remote_exchanges": r,
            "runtime_s": runtimes[qid],
        })

    return pd.DataFrame(rows)

def count_plan_nodes(dag: Dict[str, Any]) -> int:
    """Return number of operators (nodes) in a Trino plan DAG."""
    return len(dag.get("nodes", {}))

def build_nodes_vs_runtime_df(
    *,
    queries_dir: str | Path,
    workload_log_path: str | Path,
):
    """
    Returns a DataFrame with columns:
      - query
      - n_nodes
      - runtime_s
    """
    # load runtimes
    runtimes = extract_query_runtimes_s(workload_log_path)

    rows = []
    for qid, dag in iter_trino_dags_with_id(queries_dir):
        if qid not in runtimes:
            continue

        rows.append({
            "query": qid,
            "n_nodes": count_plan_nodes(dag),
            "runtime_s": runtimes[qid],
        })

    return pd.DataFrame(rows)

def operator_name(dag: Dict[str, Any], node_id: str) -> str:
    """Return operator name for a node id (safe fallback if missing)."""
    n = dag["nodes"].get(node_id)
    if not isinstance(n, dict):
        return "<MISSING_NODE>"
    return str(n.get("name", "<UNKNOWN_OP>"))


def operator_pair_counts(
    dag: Dict[str, Any],
    *,
    by_type: bool = False,
    include_types: Optional[List[str]] = None,
) -> Counter:
    """
    Count operator pairs (src_op -> dst_op) across edges.

    Parameters
    ----------
    by_type : bool
        If True, keys include edge type:
            (src_op, dst_op, etype)
        If False:
            (src_op, dst_op)

    include_types : list[str] | None
        Restrict to edge types, e.g. ["child"], ["remote"], or ["child", "remote"].

    Returns
    -------
    Counter
        Mapping operator-pair keys to counts.
    """
    c = Counter()
    allow = set(t.lower() for t in include_types) if include_types else None

    for dst, src, etype in iter_edges(dag):
        et = etype.lower()
        if allow is not None and et not in allow:
            continue

        src_op = operator_name(dag, src)
        dst_op = operator_name(dag, dst)

        if by_type:
            c[(src_op, dst_op, et)] += 1
        else:
            c[(src_op, dst_op)] += 1

    return c

def operator_type_counts(dag: Dict[str, Any]) -> Counter:
    """
    Count operator types (by name) in a single Trino plan DAG.

    Returns
    -------
    Counter
        Mapping { operator_name -> count }
    """
    c = Counter()
    for _, attrs in dag.get("nodes", {}).items():
        name = attrs.get("name")
        if name is None:
            name = "<UNKNOWN_OP>"
        c[str(name)] += 1
    return c


def operator_type_counts_many(
    dags: Iterable[Dict[str, Any]]
) -> Counter:
    """
    Aggregate operator-type counts across many DAGs.

    Useful for workload-level operator distributions.
    """
    total = Counter()
    for dag in dags:
        total.update(operator_type_counts(dag))
    return total


def operator_pair_counts_many(
    dags: Iterable[Dict[str, Any]],
    *,
    by_type: bool = False,
    include_types: Optional[List[str]] = None,
) -> Counter:
    """
    Aggregate operator-pair counts across many DAGs.

    Useful when streaming thousands of query plans.
    """
    total = Counter()
    for dag in dags:
        total.update(
            operator_pair_counts(
                dag,
                by_type=by_type,
                include_types=include_types,
            )
        )
    return total


def pretty_print_pairs(counter: Counter, top_k: int = 20) -> None:
    """Pretty-print the most common operator pairs."""
    for (key, cnt) in counter.most_common(top_k):
        if len(key) == 3:
            src, dst, etype = key
            print(f"{cnt:>6}  [{etype}]  {src} -> {dst}")
        else:
            src, dst = key
            print(f"{cnt:>6}           {src} -> {dst}")

# =======================  Workload loading ==================================

_WORKLOAD_SQL_RE = re.compile(r"^q(\d+)\.sql$", re.IGNORECASE)


def _workload_sql_sort_key(path: Path) -> tuple[int, int | str]:
    """
    Sort q1.sql, q2.sql, ..., q10.sql numerically.

    Any non-standard names are sorted after q<number>.sql files.
    """
    m = _WORKLOAD_SQL_RE.match(path.name)

    if m:
        return (0, int(m.group(1)))

    return (1, path.name)


def normalise_sql_query_name(path: Path) -> str:
    """
    Convert q1.sql -> q1.

    This keeps query identifiers consistent with the rest of the framework.
    """
    m = _WORKLOAD_SQL_RE.match(path.name)

    if m:
        return f"q{int(m.group(1))}"

    return path.stem


def iter_sql_workload(
    workload_dir: Union[str, Path],
    *,
    pattern: str = "q*.sql",
    strip_sql: bool = True,
) -> Iterator[Dict[str, Any]]:
    """
    Iterate over a pre-execution SQL workload.

    Expected structure:
        workload_dir/
            q1.sql
            q2.sql
            ...

    Yields
    ------
    dict
        {
            "query_name": "q1",
            "sql": "...",
            "path": "...",
        }
    """
    workload_dir = Path(workload_dir)

    if not workload_dir.exists():
        raise FileNotFoundError(f"Workload directory not found: {workload_dir}")

    if not workload_dir.is_dir():
        raise ValueError(f"Expected workload directory, got file: {workload_dir}")

    sql_paths = [
        p for p in workload_dir.glob(pattern)
        if p.is_file()
    ]

    sql_paths = sorted(sql_paths, key=_workload_sql_sort_key)

    for sql_path in sql_paths:
        sql = sql_path.read_text(encoding="utf-8")

        if strip_sql:
            sql = sql.strip()

        if not sql:
            continue

        yield {
            "query_name": normalise_sql_query_name(sql_path),
            "sql": sql,
            "path": str(sql_path),
        }


def load_sql_workload(
    workload_dir: Union[str, Path],
    *,
    pattern: str = "q*.sql",
    strip_sql: bool = True,
) -> Dict[str, Any]:
    """
    Load a pre-execution SQL workload into memory.

    This is intentionally independent of generation_report.json and execution
    artefacts, so it can be used for generated workloads, TPC-DS workloads,
    hand-written workloads, or any other workload following qx.sql naming.

    Returns
    -------
    dict
        {
            "workload_name": "...",
            "workload_dir": "...",
            "query_count": 100,
            "queries": {
                "q1": {
                    "query_name": "q1",
                    "sql": "...",
                    "path": "...",
                },
                ...
            }
        }
    """
    workload_dir = Path(workload_dir)

    queries: Dict[str, Any] = {}

    for record in iter_sql_workload(
        workload_dir,
        pattern=pattern,
        strip_sql=strip_sql,
    ):
        queries[record["query_name"]] = record

    if not queries:
        raise RuntimeError(
            f"No SQL queries found in {workload_dir} using pattern={pattern}"
        )

    return {
        "workload_name": workload_dir.name,
        "workload_dir": str(workload_dir),
        "query_count": len(queries),
        "queries": queries,
    }
