from __future__ import annotations

from typing import Dict, Any, List, Tuple
import numpy as np


def safe_float(x: Any, default: float = 0.0) -> float:
    try:
        return float(x)
    except Exception:
        return default


def idx_to_onehot(idx: int, num_elements: int) -> np.ndarray:
    onehot = np.zeros(num_elements, dtype=np.float32)
    onehot[idx] = 1.0
    return onehot


def get_set_encoding(source_set, onehot: bool = True):
    source_list = sorted(list(source_set))
    thing2idx = {s: i for i, s in enumerate(source_list)}
    idx2thing = [s for s in source_list]
    if onehot:
        thing2vec = {s: idx_to_onehot(i, len(source_list)) for i, s in enumerate(source_list)}
        return thing2vec, idx2thing
    return thing2idx, idx2thing


def get_all_operator_names(plans: List[Dict[str, Any]]) -> set[str]:
    ops = set()
    for dag in plans:
        for node in dag["nodes"].values():
            ops.add(node.get("name", "UNKNOWN"))
    return ops


def estimate_list_to_feature_vector(estimates: List[Dict[str, Any]]) -> np.ndarray:
    """
    Compact numeric estimate features.
    Uses log1p to stabilise large values.
    """
    if not estimates:
        return np.zeros(6, dtype=np.float32)

    row_counts = []
    output_sizes = []
    cpu_costs = []
    mem_costs = []
    net_costs = []

    for est in estimates:
        if not isinstance(est, dict):
            continue
        row_counts.append(np.log1p(max(safe_float(est.get("outputRowCount", 0.0)), 0.0)))
        output_sizes.append(np.log1p(max(safe_float(est.get("outputSizeInBytes", 0.0)), 0.0)))
        cpu_costs.append(np.log1p(max(safe_float(est.get("cpuCost", 0.0)), 0.0)))
        mem_costs.append(np.log1p(max(safe_float(est.get("memoryCost", 0.0)), 0.0)))
        net_costs.append(np.log1p(max(safe_float(est.get("networkCost", 0.0)), 0.0)))

    def mean_or_zero(vals):
        vals = [v for v in vals if np.isfinite(v)]
        return float(np.mean(vals)) if vals else 0.0

    return np.array([
        float(len(estimates)),
        mean_or_zero(row_counts),
        mean_or_zero(output_sizes),
        mean_or_zero(cpu_costs),
        mean_or_zero(mem_costs),
        mean_or_zero(net_costs),
    ], dtype=np.float32)


def build_child_tree(dag: Dict[str, Any]) -> Tuple[str, Dict[str, List[str]]]:
    """
    Build a rooted tree view using only 'child' edges.

    Returns
    -------
    root_id : str
    children : dict[node_id -> list[child_node_id]]
    """
    nodes = dag["nodes"]
    children = {nid: [] for nid in nodes}
    parent_of = {}

    for src, dst, etype in dag["edges"]:
        if etype != "child":
            continue
        children[src].append(dst)
        parent_of[dst] = src

    roots = [nid for nid in nodes if nid not in parent_of]
    if not roots:
        raise ValueError("No root found from child edges.")

    root_id = roots[0]
    return root_id, children


def count_remote_edges(dag: Dict[str, Any]) -> Tuple[Dict[str, float], Dict[str, float]]:
    remote_out = {nid: 0.0 for nid in dag["nodes"]}
    remote_in = {nid: 0.0 for nid in dag["nodes"]}

    for src, dst, etype in dag["edges"]:
        if etype == "remote":
            remote_out[src] += 1.0
            remote_in[dst] += 1.0

    return remote_in, remote_out


def safe_log(x: float, eps: float = 1e-12) -> float:
    return float(np.log(max(float(x), eps)))


def safe_exp(x: np.ndarray | float, clip_min: float = -50.0, clip_max: float = 50.0):
    x = np.asarray(x, dtype=np.float32)
    x = np.clip(x, clip_min, clip_max)
    return np.exp(x).astype(np.float32)


def runtime_from_run_df(df, xcol="t_rel_s"):
    return float(df[xcol].max())


def runtimes_from_run_dfs(run_dfs, xcol="t_rel_s") -> List[float]:
    return [runtime_from_run_df(df, xcol=xcol) for df in run_dfs]


def aggregate_query_runtime(run_dfs, xcol="t_rel_s", mode="mean"):
    runtimes = runtimes_from_run_dfs(run_dfs, xcol=xcol)
    if not runtimes:
        raise ValueError("No runtimes found.")

    if mode == "mean":
        return float(np.mean(runtimes))
    if mode == "median":
        return float(np.median(runtimes))
    if mode == "min":
        return float(np.min(runtimes))
    if mode == "max":
        return float(np.max(runtimes))
    raise ValueError(f"Unknown runtime aggregation mode: {mode}")


def runtime_to_log_label(runtime: float, eps: float = 1e-12) -> float:
    return safe_log(runtime, eps=eps)


def aggregate_query_log_runtime(run_dfs, xcol="t_rel_s", mode="mean", eps: float = 1e-12) -> float:
    runtime = aggregate_query_runtime(run_dfs, xcol=xcol, mode=mode)
    return runtime_to_log_label(runtime, eps=eps)


def runtimes_to_log_labels(runtimes, eps: float = 1e-12) -> np.ndarray:
    return np.array([runtime_to_log_label(r, eps=eps) for r in runtimes], dtype=np.float32)


def log_labels_to_runtimes(log_labels, clip_min: float = -50.0, clip_max: float = 50.0) -> np.ndarray:
    return safe_exp(log_labels, clip_min=clip_min, clip_max=clip_max)


def summarize_log_runtime_targets(log_targets) -> Dict[str, float]:
    y = np.asarray(log_targets, dtype=np.float32).reshape(-1)
    if y.size == 0:
        raise ValueError("No log-runtime targets provided.")
    return {
        "count": int(y.size),
        "mean": float(np.mean(y)),
        "std": float(np.std(y)),
        "min": float(np.min(y)),
        "max": float(np.max(y)),
    }
