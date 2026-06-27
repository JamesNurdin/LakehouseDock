# prediction/trino_numeric_encoder.py
from __future__ import annotations

import networkx as nx
import numpy as np
import pandas as pd

from dataclasses import dataclass
from typing import Any, Dict, Iterable, List, Tuple, Optional, Union
from collections import Counter, defaultdict

NUM_KEYS = ("outputRowCount", "outputSizeInBytes", "cpuCost", "memoryCost", "networkCost")

# ----------------
# Graph generating functions 
# ----------------

def trino_dag_dict_to_nx(dag: dict) -> nx.DiGraph:
    """
    Convert your plan dict DAG into a NetworkX DiGraph.

    Node attributes:
      - op (operator name)
      - fragment
      - numeric estimates if present: outputRowCount, outputSizeInBytes,
        cpuCost, memoryCost, networkCost

    Edge attributes:
      - etype ("child" or "remote")
    """
    G = nx.DiGraph()

    nodes = dag.get("nodes", {}) or {}

    def _num(x: Any) -> float:
        try:
            v = float(x)
            return float(v) if np.isfinite(v) else float("nan")
        except Exception:
            return float("nan")

    for nid, nd in nodes.items():
        op = (nd or {}).get("name", "UNK")
        frag = (nd or {}).get("fragment", None)

        est = (nd or {}).get("estimates") or []
        est0 = est[0] if est else {}

        G.add_node(
            nid,
            op=op,
            fragment=frag,
            outputRowCount=_num(est0.get("outputRowCount", np.nan)),
            outputSizeInBytes=_num(est0.get("outputSizeInBytes", np.nan)),
            cpuCost=_num(est0.get("cpuCost", np.nan)),
            memoryCost=_num(est0.get("memoryCost", np.nan)),
            networkCost=_num(est0.get("networkCost", np.nan)),
        )

    for src, dst, etype in dag.get("edges", []) or []:
        if src in nodes and dst in nodes:
            G.add_edge(src, dst, etype=etype)

    return G


def trino_graph_structural_features(G: nx.DiGraph) -> Dict[str, float]:
    """
    A small structural feature vector (baseline encoder).
    """
    ops = [d.get("op", "UNK") for _, d in G.nodes(data=True)]
    op_counts = Counter(ops)

    etypes = [d.get("etype", "child") for _, _, d in G.edges(data=True)]
    et_counts = Counter(etypes)

    frags = [d.get("fragment", None) for _, d in G.nodes(data=True)]
    n_frags = len(set([f for f in frags if f is not None]))

    try:
        longest_path = float(len(nx.dag_longest_path(G)))
    except Exception:
        longest_path = float("nan")

    feats: Dict[str, float] = {
        "n_nodes": float(G.number_of_nodes()),
        "n_edges": float(G.number_of_edges()),
        "n_fragments": float(n_frags),
        "n_remote_edges": float(et_counts.get("remote", 0)),
        "n_child_edges": float(et_counts.get("child", 0)),
        "longest_path_len": float(longest_path),
    }

    for k in [
        "TableScan", "ScanFilter", "ScanFilterProject",
        "FilterProject", "Project",
        "Aggregate",
        "InnerJoin", "LeftJoin",
        "TopN", "TopNPartial",
        "LocalExchange", "RemoteSource",
    ]:
        feats[f"op_{k}"] = float(op_counts.get(k, 0))

    return feats

_QID_RE = r"(q\d+)"


def canon_qid(qid: Union[str, None]) -> str:
    """
    Canonicalise a query id to 'qX' form (e.g. 'q2', 'q10').

    Examples
    --------
    'q2_001' -> 'q2'
    'q10'    -> 'q10'
    """
    if qid is None:
        raise ValueError("qid is None")
    s = str(qid)
    m = pd.Series([s]).str.extract(_QID_RE, expand=False).iloc[0]
    if m is None or (isinstance(m, float) and np.isnan(m)):
        raise ValueError(f"Could not canonicalise qid={qid!r}")
    return str(m)


def canon_qid_series(s: pd.Series) -> pd.Series:
    """Vectorised canonicaliser for pandas series."""
    out = s.astype(str).str.extract(_QID_RE, expand=False)
    return out


# ------------------
# Numeric Embeddings 
# ------------------

def _to_float(x: Any) -> float:
    try:
        v = float(x)
        return v if np.isfinite(v) else np.nan
    except Exception:
        return np.nan

def _log1p_safe(x: float) -> float:
    if not np.isfinite(x) or x < 0:
        return np.nan
    return float(np.log1p(x))

def _summaries(xs: np.ndarray) -> Tuple[float, float, float, float]:
    """
    Return (sum, mean, max, missing_rate) in log-space-friendly form.
    """
    xs = np.asarray(xs, dtype=float)
    miss = float(np.mean(~np.isfinite(xs))) if xs.size else 1.0
    finite = xs[np.isfinite(xs)]
    if finite.size == 0:
        return 0.0, 0.0, 0.0, 1.0
    return float(np.sum(finite)), float(np.mean(finite)), float(np.max(finite)), miss

@dataclass
class TrinoNumericPlanEncoder:
    """
    Inductive, numeric-aware embedding for Trino plan DAG dicts.

    Produces a fixed-length vector:
      [global_struct, global_numeric, per_op_numeric...]

    Key design:
    - per-operator summaries for NUM_KEYS (log1p transformed)
    - missing-rate included so "NaN-heavy" plans are distinguishable
    - op_vocab fixed from TRAIN set only (UNK bucket for unseen ops)
    """
    op_vocab: List[str]                       # fixed list (train-derived)
    include_unk: bool = True                  # add UNK bucket
    include_global: bool = True               # add global summaries
    include_counts: bool = True               # add op counts

    def _op_index(self) -> Dict[str, int]:
        vocab = list(self.op_vocab)
        if self.include_unk and "UNK" not in vocab:
            vocab.append("UNK")
        return {op: i for i, op in enumerate(vocab)}

    @classmethod
    def fit_from_train_plans(
        cls,
        train_plans: Iterable[dict],
        *,
        min_op_freq: int = 1,
        max_vocab: Optional[int] = None,
        **kwargs,
    ) -> "TrinoNumericPlanEncoder":
        c = Counter()
        for dag in train_plans:
            for _nid, nd in (dag.get("nodes") or {}).items():
                op = (nd or {}).get("name", "UNK")
                c[op] += 1
        items = [(op, n) for op, n in c.items() if n >= min_op_freq]
        items.sort(key=lambda x: (-x[1], x[0]))
        if max_vocab is not None:
            items = items[: int(max_vocab)]
        vocab = [op for op, _n in items]
        return cls(op_vocab=vocab, **kwargs)

    def encode_plan(self, dag: dict) -> np.ndarray:
        nodes = dag.get("nodes") or {}
        op2idx = self._op_index()
        vocab_size = len(op2idx)

        # For each operator and numeric key, collect log1p values
        buckets = {op: {k: [] for k in NUM_KEYS} for op in op2idx.keys()}
        op_counts = Counter()

        # Global collector too
        global_vals = {k: [] for k in NUM_KEYS}

        for _nid, nd in nodes.items():
            op = (nd or {}).get("name", "UNK")
            op = op if op in op2idx else "UNK"
            op_counts[op] += 1

            ests = (nd or {}).get("estimates") or []
            est0 = ests[0] if ests else {}

            for k in NUM_KEYS:
                v = _to_float(est0.get(k, np.nan))
                lv = _log1p_safe(v)
                buckets[op][k].append(lv)
                global_vals[k].append(lv)

        # Build vector
        parts: List[float] = []

        # ---- global blocks (optional)
        if self.include_global:
            for k in NUM_KEYS:
                s, m, mx, miss = _summaries(np.array(global_vals[k], dtype=float))
                parts.extend([s, m, mx, miss])

            # very cheap global structure signals
            parts.append(float(len(nodes)))  # n_nodes
            parts.append(float(len(dag.get("edges") or [])))  # n_edges

        # ---- per-op blocks
        # each operator contributes:
        #   [count, for each NUM_KEY: sum, mean, max, miss]
        for op in sorted(op2idx.keys(), key=lambda x: op2idx[x]):
            if self.include_counts:
                parts.append(float(op_counts.get(op, 0)))

            for k in NUM_KEYS:
                s, m, mx, miss = _summaries(np.array(buckets[op][k], dtype=float))
                parts.extend([s, m, mx, miss])

        return np.asarray(parts, dtype=float)

    def dim(self) -> int:
        op2idx = self._op_index()
        per_op = (1 if self.include_counts else 0) + (len(NUM_KEYS) * 4)
        d = len(op2idx) * per_op
        if self.include_global:
            d += len(NUM_KEYS) * 4 + 2
        return int(d)
