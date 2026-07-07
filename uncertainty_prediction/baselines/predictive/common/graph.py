"""
Shared plan-graph / plan-tree adapter for the named cost models
(QPPNet, Zero-Shot Cost Model, Reqo).

Each of those models has a *structured* native encoder: they consume the query
plan as a tree/graph of typed operators with per-operator features, not a flat
vector. This module converts a lakehouse Trino plan DAG into the tensors those
encoders need:

  op_ids   : [n]      operator-vocabulary index per node (UNK bucket)
  cont     : [n, F]   standardised continuous per-node features
  children : list[list[int]]  child indices per node (child edges only)
  post_order : list[int]      leaves-first ordering (safe for bottom-up passes)
  root     : int

Per-node continuous features available in the lakehouse (from the node's first
Trino cost estimate + local structure):
  log1p(outputRowCount, outputSizeInBytes, cpuCost, memoryCost, networkCost),
  fragment id, #children, #remote-in, #remote-out
plus a per-key missing-flag so "no estimate" is distinguishable from "zero".

Native features a Postgres reproduction would additionally use but the lakehouse
does NOT expose (documented, not faked): actual vs. estimated tuples per node,
buffer hits/reads, per-index/per-table statistics, planner width per column.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional, Sequence

import numpy as np

from uncertainty_prediction.src.trinoNumericQueryEncoder import NUM_KEYS
from uncertainty_prediction.baselines.predictive.tlstm.util import (
    build_child_tree,
    count_remote_edges,
    safe_float,
    aggregate_query_runtime,
    aggregate_query_log_runtime,
)

# number of raw continuous features per node before standardisation
_N_CONT = len(NUM_KEYS) * 2 + 4  # value + missing-flag per key, then 4 structural


def _node_raw_features(nd: Dict[str, Any], n_children: int, r_in: float, r_out: float) -> np.ndarray:
    ests = (nd or {}).get("estimates") or []
    est0 = ests[0] if ests else {}
    vals: List[float] = []
    miss: List[float] = []
    for k in NUM_KEYS:
        if k in est0 and est0.get(k) is not None:
            vals.append(float(np.log1p(max(safe_float(est0.get(k), 0.0), 0.0))))
            miss.append(0.0)
        else:
            vals.append(0.0)
            miss.append(1.0)
    fragment = safe_float((nd or {}).get("fragment", 0.0), 0.0)
    struct = [fragment, float(n_children), float(r_in), float(r_out)]
    return np.asarray(vals + miss + struct, dtype=np.float64)


def _post_order(root: int, children: Sequence[Sequence[int]]) -> List[int]:
    """Iterative post-order (leaves first). Assumes a tree over child edges."""
    order: List[int] = []
    stack = [(root, False)]
    while stack:
        node, processed = stack.pop()
        if processed:
            order.append(node)
            continue
        stack.append((node, True))
        for c in children[node]:
            stack.append((c, False))
    return order


class NodeGraphAdapter:
    """Fit operator vocab + per-node feature standardisation on train plans."""

    def __init__(self, op_vocab: List[str], mean: np.ndarray, std: np.ndarray):
        self.op_vocab = op_vocab
        self.op2idx = {op: i for i, op in enumerate(op_vocab)}
        self.unk_idx = self.op2idx["UNK"]
        self.mean = mean
        self.std = std

    @property
    def num_ops(self) -> int:
        return len(self.op_vocab)

    @property
    def cont_dim(self) -> int:
        return int(self.mean.shape[0])

    @classmethod
    def fit(
        cls,
        train_plans: Sequence[Dict[str, Any]],
        *,
        min_op_freq: int = 1,
        max_vocab: Optional[int] = None,
    ) -> "NodeGraphAdapter":
        from collections import Counter

        counter: Counter = Counter()
        raw_rows: List[np.ndarray] = []
        for dag in train_plans:
            _, children_map = build_child_tree(dag)
            r_in, r_out = count_remote_edges(dag)
            for nid, nd in (dag.get("nodes") or {}).items():
                counter[(nd or {}).get("name", "UNK")] += 1
                raw_rows.append(
                    _node_raw_features(
                        nd, len(children_map.get(nid, [])), r_in.get(nid, 0.0), r_out.get(nid, 0.0)
                    )
                )
        items = [(op, n) for op, n in counter.items() if n >= min_op_freq]
        items.sort(key=lambda x: (-x[1], x[0]))
        if max_vocab is not None:
            items = items[: int(max_vocab)]
        vocab = [op for op, _ in items]
        if "UNK" not in vocab:
            vocab.append("UNK")

        raw = np.stack(raw_rows, axis=0) if raw_rows else np.zeros((1, _N_CONT))
        mean = raw.mean(axis=0)
        std = raw.std(axis=0)
        std[std < 1e-8] = 1.0
        return cls(op_vocab=vocab, mean=mean, std=std)

    def transform_plan(self, dag: Dict[str, Any]) -> Dict[str, Any]:
        root_id, children_map = build_child_tree(dag)
        r_in, r_out = count_remote_edges(dag)
        node_ids = list((dag.get("nodes") or {}).keys())
        id2idx = {nid: i for i, nid in enumerate(node_ids)}

        n = len(node_ids)
        op_ids = np.zeros(n, dtype=np.int64)
        cont = np.zeros((n, self.cont_dim), dtype=np.float32)
        children: List[List[int]] = [[] for _ in range(n)]

        for nid in node_ids:
            i = id2idx[nid]
            nd = dag["nodes"][nid]
            op = (nd or {}).get("name", "UNK")
            op_ids[i] = self.op2idx.get(op, self.unk_idx)
            kids = children_map.get(nid, [])
            children[i] = [id2idx[k] for k in kids if k in id2idx]
            raw = _node_raw_features(nd, len(kids), r_in.get(nid, 0.0), r_out.get(nid, 0.0))
            cont[i] = ((raw - self.mean) / self.std).astype(np.float32)

        root = id2idx[root_id]
        return {
            "op_ids": op_ids,
            "cont": cont,
            "children": children,
            "post_order": _post_order(root, children),
            "root": root,
            "num_nodes": n,
        }


def build_graph_dataset(
    plans_by_query: Dict[str, Any],
    runs_by_query: Dict[str, Any],
    train_qids: Sequence[str],
    test_qids: Sequence[str],
    *,
    xcol: str = "t_rel_s",
    runtime_mode: str = "mean",
    min_op_freq: int = 1,
    max_vocab: Optional[int] = None,
) -> Dict[str, Any]:
    """
    Per-plan graph tensors + log-runtime targets for the named cost models.
    Mirrors `build_feature_dataset` but yields structured graphs instead of
    flat feature vectors.
    """

    def _keep(qids):
        return [q for q in qids if q in plans_by_query and q in runs_by_query]

    kept_train = _keep(train_qids)
    kept_test = _keep(test_qids)
    if not kept_train:
        raise ValueError("No usable training queries (missing plans or runs).")

    adapter = NodeGraphAdapter.fit(
        [plans_by_query[q] for q in kept_train], min_op_freq=min_op_freq, max_vocab=max_vocab
    )

    def _graphs(qids):
        return [adapter.transform_plan(plans_by_query[q]) for q in qids]

    def _targets(qids):
        y_log = np.array(
            [aggregate_query_log_runtime(runs_by_query[q], xcol=xcol, mode=runtime_mode) for q in qids],
            dtype=np.float32,
        )
        y_rt = np.array(
            [aggregate_query_runtime(runs_by_query[q], xcol=xcol, mode=runtime_mode) for q in qids],
            dtype=np.float32,
        )
        return y_log, y_rt

    y_train_log, y_train_runtime = _targets(kept_train)
    y_test_log, y_test_runtime = (
        _targets(kept_test) if kept_test else (np.zeros(0, np.float32), np.zeros(0, np.float32))
    )

    return {
        "adapter": adapter,
        "train_graphs": _graphs(kept_train),
        "test_graphs": _graphs(kept_test),
        "y_train_log": y_train_log,
        "y_test_log": y_test_log,
        "y_train_runtime": y_train_runtime,
        "y_test_runtime": y_test_runtime,
        "train_qids": kept_train,
        "test_qids": kept_test,
        "num_ops": adapter.num_ops,
        "cont_dim": adapter.cont_dim,
    }
