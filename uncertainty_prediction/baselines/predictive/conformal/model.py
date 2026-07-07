"""
Conformal Prediction baseline (T4 named; distribution-free CP).

Conformalized Quantile Regression (Romano et al. 2019), the method behind
github.com/ihanwen99/Conformal-Prediction-for-Verifiable-Learned-Query-optimization.
A quantile regressor is fit on a proper-training split, then a held-out
calibration split is used to conformalize each central interval so that its
marginal coverage matches the nominal target with a finite-sample guarantee.

For each target level c (50/90/99) with lower/upper quantiles (q_lo, q_hi),
the conformity score on calibration point i is

    E_i = max(q_lo(x_i) - y_i,  y_i - q_hi(x_i))

and the interval is widened by Q_{(1-alpha)}(E) where alpha = 1 - c. This makes
intervals adaptive (width still varies per query) while restoring calibration.

Point error, CRPS and uncertainty-effectiveness are read from the underlying
quantile grid; only coverage and MPIW are taken from the calibrated intervals.

Native-encoder note: CP is a wrapper around any base predictor; the encoder is
the shared `PlanFeatureAdapter` lakehouse feature table.
"""

from __future__ import annotations

from typing import Dict, Sequence, Tuple

import numpy as np

from uncertainty_prediction.baselines.predictive.common.metrics import (
    CENTRAL_LEVELS,
    QLEVELS_DEFAULT,
    _closest_level_index,
    _pair_indices,
)
from uncertainty_prediction.baselines.predictive.quantile_regression import QuantileRegression


class ConformalPrediction:
    def __init__(
        self,
        in_dim: int,
        *,
        qlevels: Sequence[float] = QLEVELS_DEFAULT,
        central_levels: Sequence[float] = CENTRAL_LEVELS,
        cal_frac: float = 0.3,
        hidden_dims=(256, 128),
        dropout: float = 0.1,
        device: str = "cpu",
        seed: int = 42,
    ):
        self.qlevels = list(qlevels)
        self.central_levels = list(central_levels)
        self.cal_frac = cal_frac
        self.seed = seed
        self.base = QuantileRegression(
            in_dim, qlevels=qlevels, hidden_dims=hidden_dims,
            dropout=dropout, device=device, seed=seed,
        )
        self._corrections: Dict[int, float] = {}  # percent level -> width correction

    def fit(
        self,
        X_train,
        y_train_log,
        *,
        num_epochs: int = 200,
        lr: float = 1e-3,
        batch_size: int = 64,
        verbose: bool = False,
    ) -> "ConformalPrediction":
        X_train = np.asarray(X_train, dtype=np.float32)
        y_train_log = np.asarray(y_train_log, dtype=np.float32).reshape(-1)

        rng = np.random.default_rng(self.seed)
        n = X_train.shape[0]
        perm = rng.permutation(n)
        n_cal = max(1, int(round(self.cal_frac * n)))
        cal_idx, fit_idx = perm[:n_cal], perm[n_cal:]

        self.base.fit(
            X_train[fit_idx], y_train_log[fit_idx],
            num_epochs=num_epochs, lr=lr, batch_size=batch_size, verbose=verbose,
        )

        # conformalize each central interval on the calibration split
        Q_cal = self.base.predict_quantiles(X_train[cal_idx])  # [n_cal, k]
        y_cal = y_train_log[cal_idx]
        for c in self.central_levels:
            lo_i, hi_i = _pair_indices(self.qlevels, c)
            scores = np.maximum(Q_cal[:, lo_i] - y_cal, y_cal - Q_cal[:, hi_i])
            alpha = 1.0 - c
            # finite-sample corrected rank
            k = int(np.ceil((n_cal + 1) * (1.0 - alpha)))
            k = min(max(k, 1), n_cal)
            correction = float(np.sort(scores)[k - 1])
            self._corrections[int(round(c * 100))] = correction
        return self

    def predict_quantiles(self, X) -> np.ndarray:
        return self.base.predict_quantiles(X)

    def predict_calibrated_intervals(self, X) -> Dict[int, Tuple[np.ndarray, np.ndarray]]:
        """Return {percent_level: (lo_log, hi_log)} widened by the CQR correction."""
        Q = self.base.predict_quantiles(X)
        out: Dict[int, Tuple[np.ndarray, np.ndarray]] = {}
        for c in self.central_levels:
            pct = int(round(c * 100))
            lo_i, hi_i = _pair_indices(self.qlevels, c)
            corr = self._corrections.get(pct, 0.0)
            out[pct] = (Q[:, lo_i] - corr, Q[:, hi_i] + corr)
        return out

    def predict_median_log(self, X) -> np.ndarray:
        Q = self.base.predict_quantiles(X)
        return Q[:, _closest_level_index(self.qlevels, 0.5)]
