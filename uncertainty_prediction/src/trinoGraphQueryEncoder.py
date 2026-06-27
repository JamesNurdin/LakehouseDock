from dataclasses import dataclass
from typing import Any, Dict, Iterable, Optional, Tuple, List, Union
from collections import Counter

import hashlib
import networkx as nx
import numpy as np


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


# -----------------------
# WL helpers (self-contained)
# -----------------------

def _stable_hash32(s: str, seed: int = 0) -> int:
    h = hashlib.blake2b((str(seed) + "|" + s).encode("utf-8"), digest_size=8).digest()
    return int.from_bytes(h, "little") & 0xFFFFFFFF


def _signed_hash_to_bucket(h: int, dim: int) -> Tuple[int, float]:
    b = int(h % dim)
    sign = -1.0 if (h >> 31) & 1 else 1.0
    return b, sign


def _initial_node_label(
    G: nx.DiGraph,
    n: Any,
    *,
    use_fragment: bool = False,
    use_estimates: bool = False,
    use_cost_estimates: bool = False,
) -> str:
    d = G.nodes[n]
    op = str(d.get("op", "UNK"))
    parts = [op]

    if use_fragment:
        frag = d.get("fragment", None)
        if frag is not None:
            parts.append(f"frag={frag}")
            
    if use_estimates:
        estimate_keys = ["outputRowCount", "outputSizeInBytes"]
        if use_cost_estimates:
            estimate_keys += ["cpuCost", "memoryCost", "networkCost"]
    
        for k in estimate_keys:
            v = d.get(k, None)
            try:
                fv = float(v)
                if np.isfinite(fv):
                    b = int(np.floor(np.log10(max(fv, 1.0))))
                    parts.append(f"{k}:10^{b}")
            except Exception:
                pass
    
    return "|".join(parts)
    


def _wl_relabel(
    G: nx.DiGraph,
    labels: Dict[Any, str],
    *,
    include_edge_types: bool = True,
    direction: str = "both",  # "in" | "out" | "both"
    seed: int = 0,
) -> Dict[Any, str]:
    new_labels: Dict[Any, str] = {}

    for n in G.nodes():
        neigh_parts: List[str] = []

        if direction in ("in", "both"):
            for u, _, ed in G.in_edges(n, data=True):
                if include_edge_types:
                    et = str(ed.get("etype", "e"))
                    neigh_parts.append(f"in:{et}:{labels[u]}")
                else:
                    neigh_parts.append(f"in:{labels[u]}")

        if direction in ("out", "both"):
            for _, v, ed in G.out_edges(n, data=True):
                if include_edge_types:
                    et = str(ed.get("etype", "e"))
                    neigh_parts.append(f"out:{et}:{labels[v]}")
                else:
                    neigh_parts.append(f"out:{labels[v]}")

        neigh_parts.sort()
        signature = labels[n] + "||" + "||".join(neigh_parts)
        new_labels[n] = f"h{_stable_hash32(signature, seed=seed)}"

    return new_labels


# -----------------------
# Core WL encoder
# -----------------------

@dataclass
class WLHashEncoder:
    """
    Inductive structural encoder using Weisfeiler–Lehman subtree hashing.

    Produces a fixed-size vector for ANY plan graph (unseen ops are fine).
    """
    dim: int = 256
    n_iter: int = 2
    include_edge_types: bool = True
    direction: str = "both"
    seed: int = 0

    # optional richer base labels
    use_fragment: bool = False
    use_estimates: bool = False
    use_cost_estimates: bool = False

    # standardisation learned from training set
    standardise: bool = True
    z_mean: Optional[np.ndarray] = None
    z_std: Optional[np.ndarray] = None

    def fit(self, plans_by_query: Dict[str, dict]) -> "WLHashEncoder":
        """
        Fit mean/std over training set (if standardise=True).
        """
        if not self.standardise:
            self.z_mean = None
            self.z_std = None
            return self

        Z = []
        for _q, dag in plans_by_query.items():
            z = self.encode(dag, standardise=False)
            Z.append(z)
        Z = np.vstack(Z) if Z else np.zeros((0, self.dim), dtype=float)

        if Z.shape[0] >= 2:
            self.z_mean = Z.mean(axis=0)
            self.z_std = Z.std(axis=0) + 1e-12
        elif Z.shape[0] == 1:
            self.z_mean = Z[0].copy()
            self.z_std = np.ones((self.dim,), dtype=float)
        else:
            self.z_mean = np.zeros((self.dim,), dtype=float)
            self.z_std = np.ones((self.dim,), dtype=float)

        return self

    def encode(self, plan_graph: dict | nx.DiGraph, *, standardise: Optional[bool] = None) -> np.ndarray:
        """
        Encode a single plan (dict or NX DiGraph) into a (dim,) vector.
        """
        if standardise is None:
            standardise = self.standardise

        if isinstance(plan_graph, nx.DiGraph):
            G = plan_graph
        else:
            G = trino_dag_dict_to_nx(plan_graph)

        labels = {
            n: _initial_node_label(G, n, use_fragment=self.use_fragment, use_estimates=self.use_estimates, use_cost_estimates=self.use_cost_estimates)
            for n in G.nodes()
        }

        all_label_counts: Dict[str, int] = dict()
        # start with initial labels
        acc = Counter(labels.values())

        # WL iterations
        for _ in range(int(self.n_iter)):
            labels = _wl_relabel(
                G,
                labels,
                include_edge_types=self.include_edge_types,
                direction=self.direction,
                seed=self.seed,
            )
            acc.update(labels.values())

        all_label_counts = acc

        # hashed bag-of-labels -> vector
        z = np.zeros((self.dim,), dtype=float)
        for lab, c in all_label_counts.items():
            h = _stable_hash32(lab, seed=self.seed)
            b, sign = _signed_hash_to_bucket(h, self.dim)
            z[b] += sign * float(c)

        # length normalise
        norm = float(np.linalg.norm(z))
        if norm > 0:
            z = z / norm

        if standardise:
            if self.z_mean is None or self.z_std is None:
                raise RuntimeError("WLHashEncoder: standardise=True but fit() has not been called.")
            z = (z - self.z_mean) / self.z_std

        return z

    def encode_many(
        self,
        plans_by_query: Dict[str, dict],
        *,
        qids: Optional[Iterable[str]] = None,
        standardise: Optional[bool] = None,
    ) -> Dict[str, np.ndarray]:
        if qids is None:
            qids = plans_by_query.keys()

        out: Dict[str, np.ndarray] = {}
        for q in qids:
            q2 = canon_qid(q)
            dag = plans_by_query.get(q2, plans_by_query.get(q, None))
            if dag is None:
                continue
            out[q2] = self.encode(dag, standardise=standardise)
        return out


# -----------------------
# TrinoGraphWLPlanEncoder (API parity with TrinoNumericPlanEncoder)
# -----------------------

@dataclass
class TrinoGraphWLPlanEncoder:
    """
    Structural plan encoder with the SAME API surface as TrinoNumericPlanEncoder.

    Methods:
      - fit_from_train_plans(train_plans, ...) -> TrinoGraphWLPlanEncoder
      - encode_plan(dag) -> np.ndarray
      - dim() -> int
    """
    emb_dim: int = 256
    n_iter: int = 2
    include_edge_types: bool = True
    direction: str = "both"
    seed: int = 0
    use_fragment: bool = False
    use_estimates: bool = False
    use_cost_estimates: bool = False
    standardise: bool = True

    _wl: Optional[WLHashEncoder] = None

    @classmethod
    def fit_from_train_plans(
        cls,
        train_plans: Iterable[dict],
        *,
        emb_dim: int = 256,
        n_iter: int = 2,
        include_edge_types: bool = True,
        direction: str = "both",
        seed: int = 0,
        use_fragment: bool = False,
        use_estimates: bool = False,
        use_cost_estimates: bool = False,
        standardise: bool = True,
        # compatibility kwargs (ignored, to mirror numeric encoder signature)
        min_op_freq: int = 1,
        max_vocab: Optional[int] = None,
        include_unk: Optional[bool] = None,
        include_global: Optional[bool] = None,
        include_counts: Optional[bool] = None,
        **_ignored_kwargs,
    ) -> "TrinoGraphWLPlanEncoder":
        self = cls(
            emb_dim=emb_dim,
            n_iter=n_iter,
            include_edge_types=include_edge_types,
            direction=direction,
            seed=seed,
            use_fragment=use_fragment,
            use_estimates=use_estimates,
            use_cost_estimates=use_cost_estimates,
            standardise=standardise,
        )

        wl = WLHashEncoder(
            dim=self.emb_dim,
            n_iter=self.n_iter,
            include_edge_types=self.include_edge_types,
            direction=self.direction,
            seed=self.seed,
            use_fragment=self.use_fragment,
            use_estimates=self.use_estimates,
            use_cost_estimates=self.use_cost_estimates,
            standardise=self.standardise,
        )

        plans_by_query = {f"train_{i}": dag for i, dag in enumerate(train_plans)}
        wl.fit(plans_by_query)
        self._wl = wl
        return self

    def encode_plan(self, dag: dict) -> np.ndarray:
        if self._wl is None:
            # allow encoding without prior fit (no standardisation)
            wl = WLHashEncoder(
                dim=self.emb_dim,
                n_iter=self.n_iter,
                include_edge_types=self.include_edge_types,
                direction=self.direction,
                seed=self.seed,
                use_fragment=self.use_fragment,
                use_estimates=self.use_estimates,
                use_cost_estimates=self.use_cost_estimates,
                standardise=False,
            )
            return wl.encode(dag, standardise=False)
        return self._wl.encode(dag, standardise=self.standardise)

    def dim(self) -> int:
        return int(self.emb_dim)