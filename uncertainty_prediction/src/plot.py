import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


def durations_from_runs(runs, *, xcol="t_rel_s"):
    """
    Extract total duration per run as max(xcol).
    Returns np.ndarray shape (n_runs,).
    """
    T = []
    for df in runs:
        if df is None or len(df) == 0 or xcol not in df.columns:
            continue
        t = float(np.nanmax(df[xcol].to_numpy()))
        if np.isfinite(t) and t > 0:
            T.append(t)
    return np.asarray(T, dtype=float)


def resample_run_to_tau(df: pd.DataFrame, tau_grid: np.ndarray, *, xcol="t_rel_s", ycol="value") -> np.ndarray:
    """
    Resample one run onto tau_grid in [0,1] using linear interpolation.
    Assumes xcol is time (seconds) and is increasing-ish.
    """
    if df is None or len(df) == 0:
        return np.full_like(tau_grid, np.nan, dtype=float)
    if xcol not in df.columns or ycol not in df.columns:
        return np.full_like(tau_grid, np.nan, dtype=float)

    d = df[[xcol, ycol]].dropna().sort_values(xcol)
    if len(d) < 2:
        return np.full_like(tau_grid, np.nan, dtype=float)

    t = d[xcol].to_numpy(dtype=float)
    y = d[ycol].to_numpy(dtype=float)
    t_end = float(t[-1])
    if not np.isfinite(t_end) or t_end <= 0:
        return np.full_like(tau_grid, np.nan, dtype=float)

    tau = t / t_end
    tau = np.clip(tau, 0.0, 1.0)

    # handle duplicate taus by taking last occurrence
    order = np.argsort(tau)
    tau = tau[order]
    y = y[order]
    _, last_idx = np.unique(tau, return_index=False, return_inverse=False, return_counts=False), None

    # np.interp requires strictly increasing x; enforce with unique
    tau_u, idx = np.unique(tau, return_index=True)
    y_u = y[idx]

    if len(tau_u) < 2:
        return np.full_like(tau_grid, np.nan, dtype=float)

    return np.interp(tau_grid, tau_u, y_u)


def plot_runtime_prediction(
    model,
    qid: str,
    *,
    Z_by_query: dict,
    runs_by_query: dict,
    xcol: str = "t_rel_s",
    n_samp: int = 20000,
    seed: int = 123,
    show_log: bool = False,
    bins: int = 50,
):
    """
    Plot runtime predictive distribution for a query and overlay true run durations.

    Expects:
      - model.predict_runtime(z) -> {"mu_log": ..., "sigma_log": ...}
    """
    if qid not in Z_by_query:
        raise KeyError(f"{qid} missing from Z_by_query")
    if qid not in runs_by_query:
        raise KeyError(f"{qid} missing from runs_by_query")

    z = Z_by_query[qid]
    runs = runs_by_query[qid]
    T_true = durations_from_runs(runs, xcol=xcol)

    rt = model.predict_runtime(np.asarray(z, dtype=float))
    mu_log = float(rt["mu_log"])
    sigma_log = float(rt["sigma_log"])

    rng = np.random.default_rng(seed)
    logT_samp = rng.normal(loc=mu_log, scale=sigma_log, size=int(n_samp))
    T_samp = np.exp(np.clip(logT_samp, -50.0, 50.0))

    # summary
    T_mean = float(np.mean(T_samp))
    T_median = float(np.median(T_samp))
    p05, p95 = float(np.quantile(T_samp, 0.05)), float(np.quantile(T_samp, 0.95))

    fig, ax = plt.subplots(figsize=(10, 5))
    if show_log:
        ax.hist(np.log(T_samp + 1e-12), bins=bins, density=True)
        ax.set_xlabel("log(runtime)")
        # overlay true in log
        for t in T_true:
            ax.axvline(np.log(t + 1e-12), linewidth=1)
        ax.axvline(np.log(T_mean + 1e-12), linewidth=2)
        ax.axvline(np.log(T_median + 1e-12), linewidth=2)
        ax.axvline(np.log(p05 + 1e-12), linewidth=1, linestyle="--")
        ax.axvline(np.log(p95 + 1e-12), linewidth=1, linestyle="--")
    else:
        ax.hist(T_samp, bins=bins, density=True)
        ax.set_xlabel("runtime (s)")
        for t in T_true:
            ax.axvline(t, linewidth=1)
        ax.axvline(T_mean, linewidth=2)
        ax.axvline(T_median, linewidth=2)
        ax.axvline(p05, linewidth=1, linestyle="--")
        ax.axvline(p95, linewidth=1, linestyle="--")

    ax.set_ylabel("density")
    ax.set_title(
        f"{qid} runtime prediction\n"
        f"mu_log={mu_log:.3f}, sigma_log={sigma_log:.3f} | "
        f"pred mean={T_mean:.3g}s, pred median={T_median:.3g}s | "
        f"p05={p05:.3g}s, p95={p95:.3g}s | "
        f"true mean={np.mean(T_true) if T_true.size else np.nan:.3g}s (n_runs={len(T_true)})"
    )
    plt.tight_layout()
    plt.show()

    return {
        "qid": qid,
        "mu_log": mu_log,
        "sigma_log": sigma_log,
        "pred_mean": T_mean,
        "pred_median": T_median,
        "p05": p05,
        "p95": p95,
        "true_mean": float(np.mean(T_true)) if T_true.size else np.nan,
        "true_median": float(np.median(T_true)) if T_true.size else np.nan,
        "true_runs": T_true,
    }


def plot_trace_prediction(
    model,
    qid: str,
    *,
    Z_by_query: dict,
    runs_by_query: dict,
    xcol: str = "t_rel_s",
    ycol: str = "value",
    band_sigma: float = 1.0,
    alpha_runs: float = 0.35,
):
    """
    Plot predicted trace mean +/- band_sigma*std over tau, with resampled true runs overlay.

    Expects:
      - model.predict_trace(z) -> {"tau_grid": ..., "mean": ..., "std": ...}
    """
    if qid not in Z_by_query:
        raise KeyError(f"{qid} missing from Z_by_query")
    if qid not in runs_by_query:
        raise KeyError(f"{qid} missing from runs_by_query")

    z = Z_by_query[qid]
    runs = runs_by_query[qid]

    tr = model.predict_trace(np.asarray(z, dtype=float))
    tau = np.asarray(tr["tau_grid"], dtype=float)
    mean_tau = np.asarray(tr["mean"], dtype=float)
    std_tau = np.asarray(tr["std"], dtype=float)

    lo = mean_tau - float(band_sigma) * std_tau
    hi = mean_tau + float(band_sigma) * std_tau

    # resample runs
    Ys = []
    for df in runs:
        y = resample_run_to_tau(df, tau, xcol=xcol, ycol=ycol)
        Ys.append(y)
    Y = np.vstack(Ys) if len(Ys) else np.empty((0, len(tau)))

    fig, ax = plt.subplots(figsize=(10, 5))

    # overlay runs
    for i in range(Y.shape[0]):
        ax.plot(tau, Y[i], alpha=alpha_runs)

    # mean + band
    ax.plot(tau, mean_tau, linewidth=2)
    ax.fill_between(tau, lo, hi, alpha=0.25)

    # quick coverage calc (ignores NaNs)
    cov = np.nan
    mae = np.nan
    if Y.size:
        mask = np.isfinite(Y) & np.isfinite(mean_tau[None, :]) & np.isfinite(lo[None, :]) & np.isfinite(hi[None, :])
        if np.any(mask):
            mae = float(np.nanmean(np.abs(Y - mean_tau[None, :])))
            cov = float(np.nanmean(((Y >= lo[None, :]) & (Y <= hi[None, :]))[mask]))

    ax.set_xlabel("tau (0=start, 1=end)")
    ax.set_ylabel(ycol)
    ax.set_title(
        f"{qid} trace prediction\n"
        f"band: ±{band_sigma}σ | trace_mae_tau={mae:.3g} | trace_cov={cov:.3g} | n_runs={len(runs)}"
    )
    plt.tight_layout()
    plt.show()

    return {"qid": qid, "trace_mae_tau": mae, "trace_cov": cov}


def plot_query_diagnostics(
    model,
    qid: str,
    runtime: bool,
    trace: bool,
    *,
    Z_by_query: dict,
    runs_by_query: dict,
    xcol: str = "t_rel_s",
    ycol: str = "value",
    runtime_show_log: bool = False,
):
    """
    Convenience: runtime + trace plots back-to-back.
    """
    rt_stats = None
    tr_stats = None
    
    if runtime:
        rt_stats = plot_runtime_prediction(
            model, qid, Z_by_query=Z_by_query, runs_by_query=runs_by_query,
            xcol=xcol, show_log=runtime_show_log
        )
    if trace:
        tr_stats = plot_trace_prediction(
            model, qid, Z_by_query=Z_by_query, runs_by_query=runs_by_query,
            xcol=xcol, ycol=ycol
        )
    return {"runtime": rt_stats, "trace": tr_stats}
