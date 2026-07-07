"""
Shared lakehouse plan -> fixed-length feature adapter for the predictive
(uncertainty-aware) baselines.

Design notes
------------
Most of the Tier-2 uncertainty *mechanisms* in the roster (Mean-Variance NLL,
MC-Dropout, Deep Ensembles, NGBoost, Quantile Regression, Conformal) are
head/wrapper methods that in their source repos sit on top of some tabular or
learned plan representation. Their native encoders were written for Postgres
`EXPLAIN` output (per-operator cardinality/cost, buffer/cache counters, index
metadata, etc.). In the Trino/Iceberg lakehouse setting most of those exact
signals do not exist, so instead of inventing Postgres fields we reuse the
*same* inductive numeric encoder the thesis model uses
(`TrinoNumericPlanEncoder`) as the shared, honest feature source. Every
mechanism therefore consumes an identical, reproducible view of each plan and
the comparison stays fair.

What is available in the lakehouse plan DAG and used here:
  - operator identity / counts (per-op vocabulary, UNK bucket for unseen ops)
  - Trino cost estimates: outputRowCount, outputSizeInBytes, cpuCost,
    memoryCost, networkCost (log1p summarised, with missing-rate signal)
  - coarse structure: n_nodes, n_edges

What a native Postgres encoder would want but the lakehouse does NOT expose
(documented so the gap is explicit, NOT silently faked):
  - actual/estimated tuple counts per node, buffer hits/reads, index scans,
    planner row estimates vs. actuals, per-table statistics targets.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional, Sequence

import numpy as np

from uncertainty_prediction.src import TrinoNumericPlanEncoder
from uncertainty_prediction.baselines.predictive.tlstm.util import (
    aggregate_query_runtime,
    aggregate_query_log_runtime,
)


class PlanFeatureAdapter:
    """
    Wraps `TrinoNumericPlanEncoder` and adds train-only standardisation.

    Fit on the training plans, then `transform` any plan into a standardised
    fixed-length float32 vector. Standardisation stats (mean/std) come from the
    training split only, so there is no test leakage.
    """

    def __init__(
        self,
        encoder: TrinoNumericPlanEncoder,
        mean: np.ndarray,
        std: np.ndarray,
    ):
        self.encoder = encoder
        self.mean = mean.astype(np.float64)
        self.std = std.astype(np.float64)

    @property
    def dim(self) -> int:
        return int(self.mean.shape[0])

    @classmethod
    def fit(
        cls,
        train_plans: Sequence[Dict[str, Any]],
        *,
        min_op_freq: int = 1,
        max_vocab: Optional[int] = None,
    ) -> "PlanFeatureAdapter":
        encoder = TrinoNumericPlanEncoder.fit_from_train_plans(
            train_plans,
            min_op_freq=min_op_freq,
            max_vocab=max_vocab,
        )
        raw = np.stack([encoder.encode_plan(dag) for dag in train_plans], axis=0)
        raw = np.nan_to_num(raw, nan=0.0, posinf=0.0, neginf=0.0).astype(np.float64)
        mean = raw.mean(axis=0)
        std = raw.std(axis=0)
        std[std < 1e-8] = 1.0  # avoid divide-by-zero on constant columns
        return cls(encoder=encoder, mean=mean, std=std)

    def transform_plan(self, dag: Dict[str, Any]) -> np.ndarray:
        raw = self.encoder.encode_plan(dag)
        raw = np.nan_to_num(raw, nan=0.0, posinf=0.0, neginf=0.0).astype(np.float64)
        z = (raw - self.mean) / self.std
        return z.astype(np.float32)

    def transform_many(self, dags: Sequence[Dict[str, Any]]) -> np.ndarray:
        if len(dags) == 0:
            return np.zeros((0, self.dim), dtype=np.float32)
        return np.stack([self.transform_plan(d) for d in dags], axis=0)


def build_feature_dataset(
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
    Build standardised feature matrices + targets for the feature-based
    predictive baselines.

    Targets are the same log-runtime labels the TLSTM baseline uses
    (`aggregate_query_log_runtime`, i.e. log of the aggregated max t_rel_s),
    so metrics are directly comparable across baselines.

    Returns a dict with:
      X_train, X_test            : float32 [n, d] standardised features
      y_train_log, y_test_log    : float32 [n]    log-runtime targets
      y_train_runtime, y_test_runtime : float32 [n] raw runtime targets
      train_qids, test_qids      : list[str] actually kept (aligned to rows)
      adapter                    : fitted PlanFeatureAdapter
      feature_dim                : int
    """

    def _keep(qids: Sequence[str]) -> List[str]:
        return [
            q for q in qids
            if q in plans_by_query and q in runs_by_query
        ]

    kept_train = _keep(train_qids)
    kept_test = _keep(test_qids)
    if len(kept_train) == 0:
        raise ValueError("No usable training queries (missing plans or runs).")

    train_plans = [plans_by_query[q] for q in kept_train]
    adapter = PlanFeatureAdapter.fit(
        train_plans, min_op_freq=min_op_freq, max_vocab=max_vocab
    )

    def _targets(qids: Sequence[str]):
        y_log = np.array(
            [aggregate_query_log_runtime(runs_by_query[q], xcol=xcol, mode=runtime_mode) for q in qids],
            dtype=np.float32,
        )
        y_rt = np.array(
            [aggregate_query_runtime(runs_by_query[q], xcol=xcol, mode=runtime_mode) for q in qids],
            dtype=np.float32,
        )
        return y_log, y_rt

    X_train = adapter.transform_many(train_plans)
    X_test = adapter.transform_many([plans_by_query[q] for q in kept_test])

    y_train_log, y_train_runtime = _targets(kept_train)
    y_test_log, y_test_runtime = (
        _targets(kept_test) if kept_test else (np.zeros(0, np.float32), np.zeros(0, np.float32))
    )

    return {
        "X_train": X_train,
        "X_test": X_test,
        "y_train_log": y_train_log,
        "y_test_log": y_test_log,
        "y_train_runtime": y_train_runtime,
        "y_test_runtime": y_test_runtime,
        "train_qids": kept_train,
        "test_qids": kept_test,
        "adapter": adapter,
        "feature_dim": adapter.dim,
    }
