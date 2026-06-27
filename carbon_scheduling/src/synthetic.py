import numpy as np
import pandas as pd


def synthesize_df_test(
        n_queries: int = 100,
        n_runs: int = 5,
        seed: int = 0,

        # runtime scale
        base_median: float = 100.0,
        max_median: float = 600.0,
        sigma_min: float = 0.10,
        sigma_max: float = 0.90,

        # prediction noise
        mu_noise: float = 0.10,
        sigma_noise: float = 0.10,
        sigma_bias: float = 0.00,
        mu_bias: float = 0.00,

        # resource scale
        cpu_min: float = 1.0,
        cpu_max: float = 8.0,
        ram_min: float = 2.0,
        ram_max: float = 32.0,

        # resource uncertainty
        cpu_sigma: float = 0.15,
        ram_sigma: float = 0.20,

        # ---------- Priority (sigmoid) ----------
        priority_high: int = 0,
        priority_low: int = 20,

        # latent x ~ Uniform(x_min, x_max)
        priority_x_min: float = 0.0,
        priority_x_max: float = 1.0,

        # sigmoid params: y = sigmoid(w0 + w1*x)
        # default chosen to bias y toward 0 -> priority near priority_high
        priority_w0: float = -2.3,
        priority_w1: float = 1.9,

        # ---------- Start time ----------
        submission_time: int = 0,
    
) -> pd.DataFrame:
    rng = np.random.default_rng(seed)

    # complexity
    z = rng.uniform(0, 1, size=n_queries)

    # ---------- runtime ----------
    med_true = base_median * (max_median / base_median) ** z
    mu_true = np.log(med_true)
    sigma_true = sigma_min + (sigma_max - sigma_min) * (z ** 1.2)

    runs = rng.lognormal(mu_true[:, None], sigma_true[:, None], size=(n_queries, n_runs))
    mean_true = runs.mean(axis=1)
    median_true = np.median(runs, axis=1)

    mu_pred = mu_true + mu_bias + rng.normal(0.0, mu_noise, size=n_queries)
    sigma_pred = (sigma_true + sigma_bias) + rng.normal(0.0, sigma_noise, size=n_queries)
    sigma_pred = np.clip(sigma_pred, 1e-3, 2.0)

    median_pred = np.exp(mu_pred)
    mean_pred = np.exp(mu_pred + 0.5 * sigma_pred ** 2)
    var_pred = (np.exp(sigma_pred ** 2) - 1.0) * np.exp(2 * mu_pred + sigma_pred ** 2)
    std_pred = np.sqrt(np.maximum(var_pred, 0.0))

    # ---------- CPU ----------
    cpu_median_true = cpu_min * (cpu_max / cpu_min) ** z
    cpu_mu_true = np.log(cpu_median_true)
    cpu_sigma_true = cpu_sigma * (0.5 + z)

    cpu_runs = rng.lognormal(cpu_mu_true[:, None], cpu_sigma_true[:, None], size=(n_queries, n_runs))

    # "actual" summaries from runs
    cpu_mean_true = cpu_runs.mean(axis=1)
    cpu_median_true_emp = np.median(cpu_runs, axis=1)
    cpu_std_true = cpu_runs.std(axis=1, ddof=1)  # variability across runs
    cpu_max_true = cpu_runs.max(axis=1)  # your “actual max” proxy

    # predicted params (noisy)
    cpu_mu_pred = cpu_mu_true + rng.normal(0.0, 0.15, size=n_queries)
    cpu_sigma_pred = cpu_sigma_true + rng.normal(0.0, 0.05, size=n_queries)
    cpu_sigma_pred = np.clip(cpu_sigma_pred, 1e-3, 2.0)

    # predicted moments (lognormal)
    cpu_median_pred = np.exp(cpu_mu_pred)
    cpu_mean_pred = np.exp(cpu_mu_pred + 0.5 * cpu_sigma_pred ** 2)
    cpu_var_pred = (np.exp(cpu_sigma_pred ** 2) - 1.0) * np.exp(2.0 * cpu_mu_pred + cpu_sigma_pred ** 2)
    cpu_std_pred = np.sqrt(np.maximum(cpu_var_pred, 0.0))

    # treat predicted mean/median as "max reservation" (your assumption)
    cpu_max_pred = cpu_mean_pred  # or cpu_median_pred

    # ---------- RAM ----------
    ram_median_true = ram_min * (ram_max / ram_min) ** (z ** 1.3)
    ram_mu_true = np.log(ram_median_true)
    ram_sigma_true = ram_sigma * (0.5 + z)

    ram_runs = rng.lognormal(ram_mu_true[:, None], ram_sigma_true[:, None], size=(n_queries, n_runs))

    # "actual" summaries from runs
    ram_mean_true = ram_runs.mean(axis=1)
    ram_median_true_emp = np.median(ram_runs, axis=1)
    ram_std_true = ram_runs.std(axis=1, ddof=1)
    ram_max_true = ram_runs.max(axis=1)

    # predicted params (noisy)
    ram_mu_pred = ram_mu_true + rng.normal(0.0, 0.20, size=n_queries)
    ram_sigma_pred = ram_sigma_true + rng.normal(0.0, 0.06, size=n_queries)
    ram_sigma_pred = np.clip(ram_sigma_pred, 1e-3, 2.0)

    # predicted moments (lognormal)
    ram_median_pred = np.exp(ram_mu_pred)
    ram_mean_pred = np.exp(ram_mu_pred + 0.5 * ram_sigma_pred ** 2)
    ram_var_pred = (np.exp(ram_sigma_pred ** 2) - 1.0) * np.exp(2.0 * ram_mu_pred + ram_sigma_pred ** 2)
    ram_std_pred = np.sqrt(np.maximum(ram_var_pred, 0.0))

    ram_max_pred = ram_mean_pred  # or ram_median_pred

    
    # ---------- Priority (sigmoid distribution via logistic sampling) ----------
    if priority_low < priority_high:
        raise ValueError("priority_low must be >= priority_high")
    
    # logistic sample → sigmoid CDF
    logistic_samples = rng.logistic(loc=priority_w0, scale=1.0/priority_w1, size=n_queries)
    
    priority_score = 1.0 / (1.0 + np.exp(-logistic_samples))  # in (0,1)
    
    # map to integer priority range
    span = priority_low - priority_high
    priority_float = priority_high + span * priority_score
    priority = np.ceil(priority_float).astype(int)
    priority = np.clip(priority, priority_high, priority_low)

    

    df = pd.DataFrame({
        "q": [f"q{i + 1}" for i in range(n_queries)],
        "n_runs": n_runs,

        # runtime preds
        "runtime_mu_log": mu_pred,
        "runtime_sigma_log": sigma_pred,
        "runtime_mean_pred": mean_pred,
        "runtime_median_pred": median_pred,
        "runtime_std_pred": std_pred,

        # runtime truth
        "runtime_mean_true": mean_true,
        "runtime_median_true": median_true,
        "runtime_std_true": sigma_true,

        # CPU preds + truth
        "cpu_mu_log_pred": cpu_mu_pred,
        "cpu_sigma_log_pred": cpu_sigma_pred,
        "cpu_mean_pred": cpu_mean_pred,
        "cpu_median_pred": cpu_median_pred,
        "cpu_std_pred": cpu_std_pred,
        "cpu_max_pred": cpu_max_pred,

        "cpu_mean_true": cpu_mean_true,
        "cpu_median_true": cpu_median_true_emp,
        "cpu_std_true": cpu_std_true,
        "cpu_max_true": cpu_max_true,

        # RAM preds + truth
        "ram_mu_log_pred": ram_mu_pred,
        "ram_sigma_log_pred": ram_sigma_pred,
        "ram_mean_pred": ram_mean_pred,
        "ram_median_pred": ram_median_pred,
        "ram_std_pred": ram_std_pred,
        "ram_max_pred": ram_max_pred,

        "ram_mean_true": ram_mean_true,
        "ram_median_true": ram_median_true_emp,
        "ram_std_true": ram_std_true,
        "ram_max_true": ram_max_true,

        "priority": priority,
        "priority_score": priority_score,   # in (0,1), useful for debugging/plots
        "priority_x": logistic_samples,       # latent

        "submission_time": submission_time,
    })

    return df