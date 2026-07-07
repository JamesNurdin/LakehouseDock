"""
Shared evaluation for the predictive baselines.

Everything the four workbook sheets need is derived from a Gaussian predictive
distribution in *log-runtime* space:

    logT ~ Normal(mu_log, sigma_log^2)

  Sheet 1 (Point error)              : MAE, RMSE (log & runtime), QError
  Sheet 2 (CRPS)                     : closed-form Gaussian CRPS in log space
  Sheet 3 (Interval quality)         : Cov@50/90/99, MPIW (at 90% nominal)
  Sheet 4 (Uncertainty effectiveness): Spearman/Pearson of sigma_log vs |error|

Sampling / ensemble methods (MC-Dropout, Deep Ensembles) are moment-matched to
a Gaussian in log space (predictive mean + std) so they flow through the same
code path and stay comparable. A separate sample-based CRPS is also provided
for when the mixture form is wanted.
"""

from __future__ import annotations

from typing import Dict, Sequence

import numpy as np
from scipy.stats import norm, spearmanr, pearsonr
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

# central prediction-interval levels reported in Sheet 3
CENTRAL_LEVELS = (0.50, 0.90, 0.99)
# nominal level at which the single reported MPIW is measured
MPIW_LEVEL = 0.90
# default quantile grid for the quantile / conformal baselines; contains the
# tails needed for the 50/90/99 central intervals plus points for CRPS.
QLEVELS_DEFAULT = (0.005, 0.025, 0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95, 0.975, 0.995)


def qerror_numpy(y_pred, y_true, eps: float = 1e-12) -> np.ndarray:
    y_pred = np.asarray(y_pred, dtype=float).reshape(-1)
    y_true = np.asarray(y_true, dtype=float).reshape(-1)
    return np.maximum((y_pred + eps) / (y_true + eps), (y_true + eps) / (y_pred + eps))


def gaussian_crps(mu: np.ndarray, sigma: np.ndarray, y: np.ndarray) -> np.ndarray:
    """
    Closed-form CRPS for a Normal(mu, sigma^2) forecast and observation y.
    Returned per-observation (same units as mu/y). Lower is better.
    """
    mu = np.asarray(mu, dtype=float).reshape(-1)
    sigma = np.asarray(sigma, dtype=float).reshape(-1)
    y = np.asarray(y, dtype=float).reshape(-1)
    sigma = np.clip(sigma, 1e-9, None)
    z = (y - mu) / sigma
    return sigma * (z * (2.0 * norm.cdf(z) - 1.0) + 2.0 * norm.pdf(z) - 1.0 / np.sqrt(np.pi))


def sample_crps(samples: np.ndarray, y: np.ndarray) -> np.ndarray:
    """
    Empirical CRPS from Monte-Carlo samples.
    samples: [S, N] (S draws per observation). y: [N].
    Uses the energy-form estimator: E|X - y| - 0.5 E|X - X'|.
    """
    samples = np.asarray(samples, dtype=float)
    y = np.asarray(y, dtype=float).reshape(-1)
    S, N = samples.shape
    term1 = np.mean(np.abs(samples - y[None, :]), axis=0)
    # 0.5 * mean_{i,j} |x_i - x_j| per observation
    diffs = np.abs(samples[:, None, :] - samples[None, :, :])  # [S, S, N]
    term2 = 0.5 * diffs.mean(axis=(0, 1))
    return term1 - term2


def coverage_and_mpiw(
    mu_log: np.ndarray,
    sigma_log: np.ndarray,
    y_log: np.ndarray,
    *,
    levels: Sequence[float] = CENTRAL_LEVELS,
    mpiw_level: float = MPIW_LEVEL,
) -> Dict[str, float]:
    """
    Central-interval coverage at each level and mean prediction-interval width
    (MPIW) at `mpiw_level`, computed in *runtime* space (exp of log interval).
    """
    mu_log = np.asarray(mu_log, dtype=float).reshape(-1)
    sigma_log = np.clip(np.asarray(sigma_log, dtype=float).reshape(-1), 1e-9, None)
    y_log = np.asarray(y_log, dtype=float).reshape(-1)

    out: Dict[str, float] = {}
    for c in levels:
        z = norm.ppf(0.5 + c / 2.0)
        lo = mu_log - z * sigma_log
        hi = mu_log + z * sigma_log
        covered = (y_log >= lo) & (y_log <= hi)
        out[f"cov@{int(round(c * 100))}"] = float(np.mean(covered))

    z = norm.ppf(0.5 + mpiw_level / 2.0)
    lo = np.exp(mu_log - z * sigma_log)
    hi = np.exp(mu_log + z * sigma_log)
    out["mpiw"] = float(np.mean(hi - lo))
    out["mpiw_log"] = float(np.mean(2.0 * z * sigma_log))
    return out


def uncertainty_effectiveness(
    sigma_log: np.ndarray,
    mu_log: np.ndarray,
    y_log: np.ndarray,
) -> Dict[str, float]:
    """
    Correlation between predicted uncertainty (sigma_log) and realised absolute
    error |y_log - mu_log|. Higher (more positive) is better.
    """
    sigma_log = np.asarray(sigma_log, dtype=float).reshape(-1)
    abs_err = np.abs(np.asarray(y_log, dtype=float).reshape(-1) - np.asarray(mu_log, dtype=float).reshape(-1))

    if np.std(sigma_log) < 1e-12 or np.std(abs_err) < 1e-12:
        return {"unc_spearman": 0.0, "unc_pearson": 0.0}

    sp = spearmanr(sigma_log, abs_err).statistic
    pr = pearsonr(sigma_log, abs_err)[0]
    return {
        "unc_spearman": float(sp) if sp is not None and np.isfinite(sp) else 0.0,
        "unc_pearson": float(pr) if pr is not None and np.isfinite(pr) else 0.0,
    }


def evaluate_point_predictions(preds_runtime, labels_runtime, eps: float = 1e-12) -> Dict[str, float]:
    preds = np.asarray(preds_runtime, dtype=float).reshape(-1)
    labels = np.asarray(labels_runtime, dtype=float).reshape(-1)
    qerr = qerror_numpy(preds, labels)
    sp = spearmanr(labels, preds).statistic if np.std(preds) > 1e-12 else 0.0
    return {
        "mae": float(mean_absolute_error(labels, preds)),
        "rmse": float(np.sqrt(mean_squared_error(labels, preds))),
        "r2": float(r2_score(labels, preds)) if np.std(labels) > 1e-12 else 0.0,
        "spearman": float(sp) if sp is not None and np.isfinite(sp) else 0.0,
        "median_q_error": float(np.median(qerr)),
        "mean_q_error": float(np.mean(qerr)),
        "gmean_q_error": float(np.exp(np.mean(np.log(qerr + eps)))),
        "p90_q_error": float(np.percentile(qerr, 90)),
        "p95_q_error": float(np.percentile(qerr, 95)),
        "max_q_error": float(np.max(qerr)),
    }


def evaluate_gaussian_predictions(
    mu_log: np.ndarray,
    sigma_log: np.ndarray,
    y_log: np.ndarray,
) -> Dict[str, float]:
    """
    Full metric bundle for one model on one (dataset, metric) block, from a
    Gaussian predictive distribution in log space. Point predictions use the
    log-normal median exp(mu_log).
    """
    mu_log = np.asarray(mu_log, dtype=float).reshape(-1)
    sigma_log = np.clip(np.asarray(sigma_log, dtype=float).reshape(-1), 1e-9, None)
    y_log = np.asarray(y_log, dtype=float).reshape(-1)

    preds_rt = np.exp(mu_log)
    labels_rt = np.exp(y_log)

    metrics: Dict[str, float] = {}
    # ---- Sheet 1: point error ----
    metrics["mae_log"] = float(mean_absolute_error(y_log, mu_log))
    metrics["rmse_log"] = float(np.sqrt(mean_squared_error(y_log, mu_log)))
    metrics.update(evaluate_point_predictions(preds_rt, labels_rt))
    # ---- Sheet 2: CRPS (log space) ----
    metrics["crps"] = float(np.mean(gaussian_crps(mu_log, sigma_log, y_log)))
    # ---- Sheet 3: interval quality ----
    metrics.update(coverage_and_mpiw(mu_log, sigma_log, y_log))
    # ---- Sheet 4: uncertainty effectiveness ----
    metrics.update(uncertainty_effectiveness(sigma_log, mu_log, y_log))
    # helpful extras
    metrics["mean_sigma_log"] = float(np.mean(sigma_log))
    metrics["median_sigma_log"] = float(np.median(sigma_log))
    return metrics


# ---------------------------------------------------------------------------
# Quantile / interval based predictors (Quantile Regression, Conformal)
# ---------------------------------------------------------------------------

def _closest_level_index(qlevels: Sequence[float], target: float) -> int:
    return int(np.argmin(np.abs(np.asarray(qlevels, dtype=float) - target)))


def _pair_indices(qlevels: Sequence[float], central: float):
    """Indices of the lower/upper quantiles bounding a central interval."""
    lo = 0.5 - central / 2.0
    hi = 0.5 + central / 2.0
    return _closest_level_index(qlevels, lo), _closest_level_index(qlevels, hi)


def pinball_loss(level: float, pred_q: np.ndarray, y: np.ndarray) -> np.ndarray:
    """Per-observation pinball (quantile) loss for a single quantile level."""
    pred_q = np.asarray(pred_q, dtype=float).reshape(-1)
    y = np.asarray(y, dtype=float).reshape(-1)
    diff = y - pred_q
    return np.maximum(level * diff, (level - 1.0) * diff)


def crps_from_quantiles(qlevels: Sequence[float], Q: np.ndarray, y: np.ndarray) -> np.ndarray:
    """
    Approximate CRPS from a quantile grid using CRPS = 2 * integral_0^1 pinball_tau dtau,
    estimated as 2 * mean over the provided quantile levels. Q: [n, k], y: [n].
    """
    qlevels = np.asarray(qlevels, dtype=float)
    Q = np.asarray(Q, dtype=float)
    y = np.asarray(y, dtype=float).reshape(-1)
    losses = np.stack([pinball_loss(q, Q[:, j], y) for j, q in enumerate(qlevels)], axis=1)  # [n, k]
    return 2.0 * losses.mean(axis=1)


def evaluate_quantile_predictions(
    qlevels: Sequence[float],
    Q_log: np.ndarray,
    y_log: np.ndarray,
    *,
    levels: Sequence[float] = CENTRAL_LEVELS,
    mpiw_level: float = MPIW_LEVEL,
) -> Dict[str, float]:
    """
    Full metric bundle for a quantile predictor. Q_log is [n, k] of predicted
    log-runtime quantiles aligned to `qlevels` (assumed non-crossing / sorted).
    Point prediction is the predicted median.
    """
    qlevels = list(qlevels)
    Q_log = np.asarray(Q_log, dtype=float)
    y_log = np.asarray(y_log, dtype=float).reshape(-1)

    med_idx = _closest_level_index(qlevels, 0.5)
    mu_log = Q_log[:, med_idx]
    preds_rt = np.exp(mu_log)
    labels_rt = np.exp(y_log)

    metrics: Dict[str, float] = {}
    metrics["mae_log"] = float(mean_absolute_error(y_log, mu_log))
    metrics["rmse_log"] = float(np.sqrt(mean_squared_error(y_log, mu_log)))
    metrics.update(evaluate_point_predictions(preds_rt, labels_rt))
    metrics["crps"] = float(np.mean(crps_from_quantiles(qlevels, Q_log, y_log)))

    for c in levels:
        lo_i, hi_i = _pair_indices(qlevels, c)
        covered = (y_log >= Q_log[:, lo_i]) & (y_log <= Q_log[:, hi_i])
        metrics[f"cov@{int(round(c * 100))}"] = float(np.mean(covered))
    lo_i, hi_i = _pair_indices(qlevels, mpiw_level)
    metrics["mpiw"] = float(np.mean(np.exp(Q_log[:, hi_i]) - np.exp(Q_log[:, lo_i])))
    metrics["mpiw_log"] = float(np.mean(Q_log[:, hi_i] - Q_log[:, lo_i]))

    # uncertainty proxy = interval width at mpiw_level
    width = Q_log[:, hi_i] - Q_log[:, lo_i]
    metrics.update(uncertainty_effectiveness(width, mu_log, y_log))
    return metrics


def override_with_calibrated_intervals(
    metrics: Dict[str, float],
    calibrated_log: Dict[int, tuple],
    y_log: np.ndarray,
    *,
    mpiw_level: float = MPIW_LEVEL,
) -> Dict[str, float]:
    """
    Replace cov@ and mpiw entries with values from conformally-calibrated
    intervals. `calibrated_log` maps percent level (50/90/99) -> (lo_log, hi_log)
    arrays. Point error / CRPS / uncertainty-effectiveness are left as supplied.
    """
    y_log = np.asarray(y_log, dtype=float).reshape(-1)
    out = dict(metrics)
    for pct, (lo, hi) in calibrated_log.items():
        lo = np.asarray(lo, dtype=float).reshape(-1)
        hi = np.asarray(hi, dtype=float).reshape(-1)
        out[f"cov@{pct}"] = float(np.mean((y_log >= lo) & (y_log <= hi)))
        if pct == int(round(mpiw_level * 100)):
            out["mpiw"] = float(np.mean(np.exp(hi) - np.exp(lo)))
            out["mpiw_log"] = float(np.mean(hi - lo))
    return out


def print_metric_headers_for_excel(metrics: Dict[str, float]) -> None:
    print("\t".join(metrics.keys()))


def print_metrics_for_excel(metrics: Dict[str, float]) -> None:
    print("\t".join(str(v) for v in metrics.values()))
