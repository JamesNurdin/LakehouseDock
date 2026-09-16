"""A lightweight, non-learned epistemic uncertainty signal for QPP.

Extracted verbatim (methodology unchanged) from
``exposure_knn_nonlearned_epistemic_uncertainty.ipynb`` so it can be
``import``ed by other code (e.g. ``workload_generation/hybrid/v2``) instead
of being redefined inline. That notebook is the canonical writeup —
methodology, both AUROC evaluations (template-holdout and cross-workload
against labelled ID/OOD splits from genuine data provenance, never against a
model's own prediction error), and the literature this follows (Sun et al.,
ICML 2022; Lee et al., NeurIPS 2018) — read it first if the "why" here isn't
obvious from the docstrings alone.

Method, in one line, no target involved:

    novelty(query) = mean k-NN distance to a reference set,
                     over standardised (operator-motif, leaf-cardinality) features

No target/label is ever passed in, at fit time or at scoring time — that's
what makes "deemed out of distribution" a checkable, non-circular claim
rather than an assertion smuggling in some other model's biases.
"""

from __future__ import annotations

from collections import Counter
from typing import Any, Dict, Iterable, List

import numpy as np
from sklearn.neighbors import NearestNeighbors

from uncertainty_prediction.baselines.predictive.tlstm.util import build_child_tree

__all__ = [
    "op_bigrams", "op_trigrams", "combined_motifs",
    "leaf_scan_log_cards", "card_summary", "ExposureNovelty",
]


def _memoize_by_plan_identity(fn):
    """Caches by id(dag): callers typically hold plan dicts by pointer (e.g.
    a `plans_by_query` dict loaded once and referenced everywhere after), so
    this avoids re-walking the same plan's operator tree on every call that
    touches it (`w_motif`/`w_card` don't change the raw features, only how
    they're standardised and weighted downstream)."""
    cache: Dict[int, Any] = {}

    def wrapper(dag):
        key = id(dag)
        if key not in cache:
            cache[key] = fn(dag)
        return cache[key]

    return wrapper


def op_bigrams(dag: Dict[str, Any]) -> Counter:
    _, children = build_child_tree(dag)
    names = {nid: (nd or {}).get("name", "UNK") for nid, nd in dag["nodes"].items()}
    grams: Counter = Counter()
    for pid, kids in children.items():
        for cid in kids:
            grams[(names[pid], names[cid])] += 1
    return grams


def op_trigrams(dag: Dict[str, Any]) -> Counter:
    _, children = build_child_tree(dag)
    names = {nid: (nd or {}).get("name", "UNK") for nid, nd in dag["nodes"].items()}
    grams: Counter = Counter()
    for gid, kids in children.items():
        for pid in kids:
            for cid in children.get(pid, []):
                grams[(names[gid], names[pid], names[cid])] += 1
    return grams


@_memoize_by_plan_identity
def combined_motifs(dag: Dict[str, Any]) -> Counter:
    g: Counter = Counter()
    for k, v in op_bigrams(dag).items():
        g[("bi",) + k] += v
    for k, v in op_trigrams(dag).items():
        g[("tri",) + k] += v
    return g


@_memoize_by_plan_identity
def leaf_scan_log_cards(dag: Dict[str, Any]) -> np.ndarray:
    vals: List[float] = []
    for nd in dag["nodes"].values():
        name = (nd or {}).get("name", "")
        if "Scan" not in name:
            continue
        ests = nd.get("estimates") or []
        if not ests:
            continue
        rc = ests[0].get("outputRowCount")
        if rc is not None and np.isfinite(rc) and rc >= 0:
            vals.append(np.log1p(float(rc)))
    return np.asarray(vals, dtype=np.float64)


@_memoize_by_plan_identity
def card_summary(dag: Dict[str, Any]) -> np.ndarray:
    v = leaf_scan_log_cards(dag)
    if v.size == 0:
        return np.array([0.0, 0.0, 0.0, 0.0, 0.0, 1.0])
    return np.array([v.min(), np.percentile(v, 25), np.median(v), np.percentile(v, 75), v.max(), 0.0])


class ExposureNovelty:
    """Pure structural/cardinality novelty scorer. Fits a k-NN index over
    standardised, independently-weighted (motif, cardinality) feature
    blocks; reports mean k-NN distance as novelty. No target anywhere --
    not at fit time, not at scoring time -- so there is nothing here to
    validate against a model's error, by construction.

    Two feature blocks, entirely hand-crafted, no learned component:
      - structural: normalised counts of (parent-operator -> child-operator)
        motifs (bigrams and trigrams) along the plan's child-edge tree.
      - cardinality: [min, p25, median, p75, max] of log1p(outputRowCount)
        over leaf-scan nodes -- the only nodes with reliably non-NaN
        cardinality estimates in this lakehouse's plan format.
    """

    def __init__(self, k: int = 5, w_motif: float = 1.0, w_card: float = 1.0,
                 motif_vocab_size: int = 200, seed: int = 42):
        self.k = k
        self.w_motif = w_motif
        self.w_card = w_card
        self.motif_vocab_size = motif_vocab_size
        self.seed = seed

    def _motif_vector(self, dag: Dict[str, Any]) -> np.ndarray:
        grams = combined_motifs(dag)
        vec = np.zeros(len(self.vocab_) + 1, dtype=np.float64)
        total = sum(grams.values()) or 1
        for g, v in grams.items():
            idx = self.motif2idx_.get(g)
            if idx is None:
                vec[-1] += v / total
            else:
                vec[idx] += v / total
        return vec

    def _blocks(self, plans: Iterable[Dict[str, Any]]) -> np.ndarray:
        Xm = np.stack([self._motif_vector(d) for d in plans])
        Xc = np.stack([card_summary(d) for d in plans])
        Zm = ((Xm - self.motif_mean_) / self.motif_std_) * np.sqrt(self.w_motif)
        Zc = ((Xc - self.card_mean_) / self.card_std_) * np.sqrt(self.w_card)
        return np.concatenate([Zm, Zc], axis=1)

    def fit(self, plans: Iterable[Dict[str, Any]]) -> "ExposureNovelty":
        plans = list(plans)
        df: Counter = Counter()
        for dag in plans:
            for g in combined_motifs(dag):
                df[g] += 1
        self.vocab_ = [g for g, _ in df.most_common(self.motif_vocab_size)]
        self.motif2idx_ = {g: i for i, g in enumerate(self.vocab_)}

        Xm = np.stack([self._motif_vector(d) for d in plans])
        Xc = np.stack([card_summary(d) for d in plans])
        self.motif_mean_, self.motif_std_ = Xm.mean(0), Xm.std(0)
        self.motif_std_[self.motif_std_ < 1e-8] = 1.0
        self.card_mean_, self.card_std_ = Xc.mean(0), Xc.std(0)
        self.card_std_[self.card_std_ < 1e-8] = 1.0

        Z = self._blocks(plans)
        self.nn_ = NearestNeighbors(n_neighbors=min(self.k, len(plans))).fit(Z)
        return self

    def novelty(self, plans: Iterable[Dict[str, Any]]) -> np.ndarray:
        Z = self._blocks(list(plans))
        dist, _ = self.nn_.kneighbors(Z)
        return dist.mean(axis=1)
