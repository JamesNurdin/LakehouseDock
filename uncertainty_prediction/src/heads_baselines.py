"""
Shared-embedding uncertainty baselines (Tier 2 / Tier 3).

Every head here implements the same RuntimeHead contract as heads_v1 /
heads_v2, so it drops straight into `evaluate_unseen_queries` via
`runtime_head_cls` / `runtime_head_kwargs` with no pipeline changes:

    fit(Z, logT_targets) -> self
    predict(z) -> {"mu_log": float, "sigma_log": float, ...}
    sample(z, *, rng, n) -> (n,) samples of T (seconds)

All operate on the *shared* query embedding Z (e.g. WL or GIN), so they are
apples-to-apples comparators to your own model on latency.

Heads
-----
DeepEnsembleRuntimeHead   Lakshminarayanan et al. 2017  (aleatoric + epistemic)
MCDropoutRuntimeHead      Gal & Ghahramani 2016         (epistemic approx + noise)
NGBoostRuntimeHead        Duan et al. 2020              (full distribution; needs `ngboost`)
QuantileRuntimeHead       pinball / multi-quantile      (distribution-free)
GPRuntimeHead             NNGP (Lee et al. 2018) / RBF  (closed-form Gaussian)

Notes
-----
- Targets are log-runtime (logT); predictive is Gaussian in log-space, i.e.
  T is lognormal. `predict` returns {mu_log, sigma_log} to match your
  lognormal evaluation contract. Sampling-capable heads also expose richer
  info (per-member spread, quantiles) for empirical CRPS / native coverage.
- Z is standardised internally on the training set, as in your other heads.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Sequence, Tuple, Type

import numpy as np

from .heads_v1 import MLPHeteroRuntimeHead

__all__ = [
    "DeepEnsembleRuntimeHead",
    "MCDropoutRuntimeHead",
    "NGBoostRuntimeHead",
    "QuantileRuntimeHead",
    "GPRuntimeHead",
]


# -----------------------------------------------------------------------------
# small shared utilities (kept local so this module is self-contained)
# -----------------------------------------------------------------------------

def _safe_exp(x: np.ndarray, *, max_x: float = 50.0) -> np.ndarray:
    x = np.asarray(x, dtype=float)
    return np.exp(np.clip(x, a_min=-max_x, a_max=max_x))


def _clip_sigma(sigma: float, lo: float = 1e-6, hi: float = 50.0) -> float:
    return float(np.clip(float(sigma), lo, hi))


def _fit_standardiser(Z: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
    Z = np.asarray(Z, dtype=float)
    mean = Z.mean(axis=0)
    std = Z.std(axis=0) + 1e-12
    return mean, std


# -----------------------------------------------------------------------------
# Deep Ensembles (Lakshminarayanan et al., 2017)
# -----------------------------------------------------------------------------

@dataclass
class DeepEnsembleRuntimeHead:
    """
    Ensemble of M heteroscedastic Gaussian-NLL heads with independent init.

    The predictive is a Gaussian mixture; we report the moment-matched Gaussian
        mu*      = mean_m mu_m
        var*     = mean_m sigma_m^2   (aleatoric)
                 + var_m  mu_m        (epistemic)
    which cleanly separates aleatoric and epistemic uncertainty. This mechanism
    also stands in for Fauce.
    """
    n_members: int = 5
    bootstrap: bool = False
    seed: int = 0

    # per-member config (defaults mirror MLPHeteroRuntimeHead)
    hidden: int = 64
    lr: float = 1e-2
    steps: int = 3000
    weight_decay: float = 1e-4
    member_cls: Type = MLPHeteroRuntimeHead
    member_kwargs: Dict[str, Any] = field(default_factory=dict)

    members_: List[Any] = field(default_factory=list)
    meta: Dict[str, Any] = None

    def fit(self, Z: np.ndarray, logT_targets: np.ndarray) -> "DeepEnsembleRuntimeHead":
        Z = np.asarray(Z, dtype=float)
        y = np.asarray(logT_targets, dtype=float).reshape(-1)
        n = Z.shape[0]
        if n < 3:
            raise ValueError("Need at least 3 training samples for DeepEnsembleRuntimeHead")

        rng = np.random.default_rng(self.seed)
        self.members_ = []
        for m in range(int(self.n_members)):
            kwargs = dict(
                hidden=self.hidden, lr=self.lr, steps=self.steps,
                weight_decay=self.weight_decay, seed=self.seed + m,
            )
            kwargs.update(self.member_kwargs)
            head = self.member_cls(**kwargs)

            if self.bootstrap:
                idx = rng.integers(0, n, size=n)
                head.fit(Z[idx], y[idx])
            else:
                head.fit(Z, y)
            self.members_.append(head)

        self.meta = {
            "kind": "deep_ensemble_runtime_head",
            "n_members": int(self.n_members),
            "bootstrap": bool(self.bootstrap),
            "member": getattr(self.member_cls, "__name__", str(self.member_cls)),
        }
        return self

    def _member_params(self, z: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        mus, sigmas = [], []
        for head in self.members_:
            p = head.predict(z)
            mus.append(float(p["mu_log"]))
            sigmas.append(float(p["sigma_log"]))
        return np.asarray(mus), np.asarray(sigmas)

    def predict(self, z: np.ndarray) -> Dict[str, float]:
        if not self.members_:
            raise RuntimeError("DeepEnsembleRuntimeHead not fit")
        mus, sigmas = self._member_params(z)

        mu = float(np.mean(mus))
        var_aleatoric = float(np.mean(sigmas ** 2))
        var_epistemic = float(np.var(mus, ddof=0))
        sigma = _clip_sigma(np.sqrt(var_aleatoric + var_epistemic))

        return {
            "mu_log": float(np.clip(mu, -20.0, 20.0)),
            "sigma_log": sigma,
            "sigma_aleatoric": _clip_sigma(np.sqrt(var_aleatoric)),
            "sigma_epistemic": _clip_sigma(np.sqrt(max(var_epistemic, 0.0))),
        }

    def sample(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray:
        """Proper mixture sampling: pick a member per draw, then sample its Gaussian."""
        mus, sigmas = self._member_params(z)
        m = len(mus)
        choice = rng.integers(0, m, size=int(n))
        logT = rng.normal(loc=mus[choice], scale=np.maximum(sigmas[choice], 1e-6))
        return _safe_exp(logT)


# -----------------------------------------------------------------------------
# MC-Dropout (Gal & Ghahramani, 2016)
# -----------------------------------------------------------------------------

@dataclass
class MCDropoutRuntimeHead:
    """
    MLP trained with dropout; dropout is kept ON at test time and we take
    `n_passes` stochastic forward passes.

        mu*   = mean over passes            (predictive mean)
        var*  = var over passes             (epistemic)
              + sigma_noise^2               (aleatoric; homoscedastic, from residuals)

    Stands in for HyperQO's uncertainty mechanism.
    """
    hidden: int = 64
    dropout: float = 0.1
    lr: float = 1e-2
    steps: int = 3000
    weight_decay: float = 1e-4
    clip_grad: float = 5.0
    n_passes: int = 50
    seed: int = 0
    device: str = "cpu"

    _net: Any = None
    z_mean: Optional[np.ndarray] = None
    z_std: Optional[np.ndarray] = None
    sigma_noise: float = 1.0
    meta: Dict[str, Any] = None

    def _build(self, d: int):
        import torch.nn as nn

        class _Net(nn.Module):
            def __init__(self, d_in, hidden, p):
                super().__init__()
                self.net = nn.Sequential(
                    nn.Linear(d_in, hidden), nn.ReLU(), nn.Dropout(p),
                    nn.Linear(hidden, hidden), nn.ReLU(), nn.Dropout(p),
                    nn.Linear(hidden, 1),
                )

            def forward(self, x):
                return self.net(x).squeeze(-1)

        return _Net(d, int(self.hidden), float(self.dropout))

    def fit(self, Z: np.ndarray, logT_targets: np.ndarray) -> "MCDropoutRuntimeHead":
        import torch

        Z = np.asarray(Z, dtype=np.float32)
        y = np.asarray(logT_targets, dtype=np.float32).reshape(-1)
        n, d = Z.shape
        if n < 3:
            raise ValueError("Need at least 3 training samples for MCDropoutRuntimeHead")

        torch.manual_seed(int(self.seed))
        np.random.seed(int(self.seed))

        self.z_mean, self.z_std = _fit_standardiser(Z)
        Zs = ((Z - self.z_mean) / self.z_std).astype(np.float32)

        dev = torch.device(self.device)
        X = torch.as_tensor(Zs, device=dev)
        yt = torch.as_tensor(y, device=dev)

        self._net = self._build(d).to(dev)
        opt = torch.optim.AdamW(self._net.parameters(), lr=float(self.lr), weight_decay=float(self.weight_decay))

        self._net.train()
        for _ in range(int(self.steps)):
            opt.zero_grad()
            pred = self._net(X)
            loss = torch.mean((pred - yt) ** 2)
            loss.backward()
            torch.nn.utils.clip_grad_norm_(self._net.parameters(), max_norm=float(self.clip_grad))
            opt.step()

        # homoscedastic aleatoric noise from training residuals (eval mode = no dropout)
        self._net.eval()
        with torch.no_grad():
            mu_train = self._net(X).cpu().numpy()
        self.sigma_noise = float(max(np.std(y - mu_train, ddof=1), 1e-6))

        self.meta = {
            "kind": "mc_dropout_runtime_head",
            "d": int(d), "hidden": int(self.hidden), "dropout": float(self.dropout),
            "n_passes": int(self.n_passes), "sigma_noise": self.sigma_noise,
        }
        return self

    def _passes(self, z: np.ndarray) -> np.ndarray:
        import torch
        zs = ((np.asarray(z, dtype=np.float32).reshape(1, -1) - self.z_mean) / self.z_std).astype(np.float32)
        dev = next(self._net.parameters()).device
        x = torch.as_tensor(zs, device=dev).repeat(int(self.n_passes), 1)
        self._net.train()  # keep dropout active
        with torch.no_grad():
            out = self._net(x).cpu().numpy()
        return out.reshape(-1)

    def predict(self, z: np.ndarray) -> Dict[str, float]:
        if self._net is None:
            raise RuntimeError("MCDropoutRuntimeHead not fit")
        passes = self._passes(z)
        mu = float(np.mean(passes))
        var_epistemic = float(np.var(passes, ddof=0))
        sigma = _clip_sigma(np.sqrt(var_epistemic + self.sigma_noise ** 2))
        return {
            "mu_log": float(np.clip(mu, -20.0, 20.0)),
            "sigma_log": sigma,
            "sigma_aleatoric": _clip_sigma(self.sigma_noise),
            "sigma_epistemic": _clip_sigma(np.sqrt(var_epistemic)),
        }

    def sample(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray:
        passes = self._passes(z)
        base = rng.choice(passes, size=int(n), replace=True)
        logT = base + rng.normal(0.0, self.sigma_noise, size=int(n))
        return _safe_exp(logT)


# -----------------------------------------------------------------------------
# NGBoost (Duan et al., 2020)
# -----------------------------------------------------------------------------

@dataclass
class NGBoostRuntimeHead:
    """
    Natural Gradient Boosting with a Normal distribution over logT.

    Requires the `ngboost` package (pip install ngboost). Predicts a full
    Gaussian per query; we read loc/scale directly as (mu_log, sigma_log).
    """
    n_estimators: int = 500
    learning_rate: float = 0.01
    minibatch_frac: float = 1.0
    seed: int = 0
    verbose: bool = False

    _model: Any = None
    meta: Dict[str, Any] = None

    def fit(self, Z: np.ndarray, logT_targets: np.ndarray) -> "NGBoostRuntimeHead":
        try:
            from ngboost import NGBRegressor
            from ngboost.distns import Normal
        except Exception as e:  # pragma: no cover - dependency guard
            raise ImportError(
                "NGBoostRuntimeHead requires the 'ngboost' package. Install it with "
                "`pip install ngboost`."
            ) from e

        Z = np.asarray(Z, dtype=float)
        y = np.asarray(logT_targets, dtype=float).reshape(-1)
        if Z.shape[0] < 3:
            raise ValueError("Need at least 3 training samples for NGBoostRuntimeHead")

        self._model = NGBRegressor(
            Dist=Normal,
            n_estimators=int(self.n_estimators),
            learning_rate=float(self.learning_rate),
            minibatch_frac=float(self.minibatch_frac),
            random_state=int(self.seed),
            verbose=bool(self.verbose),
        )
        self._model.fit(Z, y)
        self.meta = {"kind": "ngboost_runtime_head", "n_estimators": int(self.n_estimators)}
        return self

    def _dist_params(self, z: np.ndarray) -> Tuple[float, float]:
        z = np.asarray(z, dtype=float).reshape(1, -1)
        dist = self._model.pred_dist(z)
        loc = float(np.asarray(dist.params["loc"]).reshape(-1)[0])
        scale = float(np.asarray(dist.params["scale"]).reshape(-1)[0])
        return loc, scale

    def predict(self, z: np.ndarray) -> Dict[str, float]:
        if self._model is None:
            raise RuntimeError("NGBoostRuntimeHead not fit")
        mu, sigma = self._dist_params(z)
        return {"mu_log": float(np.clip(mu, -20.0, 20.0)), "sigma_log": _clip_sigma(sigma)}

    def sample(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray:
        mu, sigma = self._dist_params(z)
        logT = rng.normal(loc=mu, scale=max(sigma, 1e-6), size=int(n))
        return _safe_exp(logT)


# -----------------------------------------------------------------------------
# Quantile Regression (pinball loss, multi-quantile)
# -----------------------------------------------------------------------------

@dataclass
class QuantileRuntimeHead:
    """
    Distribution-free multi-quantile head trained with pinball loss on logT.

    Exposes:
      - predict(z): moment-matched {mu_log, sigma_log} (median + central-quantile
        spread) so it works in your lognormal evaluator, plus the raw quantiles.
      - predict_quantiles(z): {level: value_log} for native coverage / CRPS.
      - sample(z): inverse-CDF sampling over the quantile grid.
    """
    quantiles: Sequence[float] = (0.05, 0.1, 0.16, 0.25, 0.5, 0.75, 0.84, 0.9, 0.95)
    hidden: int = 64
    lr: float = 1e-2
    steps: int = 3000
    weight_decay: float = 1e-4
    clip_grad: float = 5.0
    seed: int = 0
    device: str = "cpu"

    _net: Any = None
    _levels: Optional[np.ndarray] = None
    z_mean: Optional[np.ndarray] = None
    z_std: Optional[np.ndarray] = None
    meta: Dict[str, Any] = None

    def fit(self, Z: np.ndarray, logT_targets: np.ndarray) -> "QuantileRuntimeHead":
        import torch
        import torch.nn as nn

        Z = np.asarray(Z, dtype=np.float32)
        y = np.asarray(logT_targets, dtype=np.float32).reshape(-1)
        n, d = Z.shape
        if n < 3:
            raise ValueError("Need at least 3 training samples for QuantileRuntimeHead")

        torch.manual_seed(int(self.seed))
        np.random.seed(int(self.seed))

        self._levels = np.asarray(sorted(self.quantiles), dtype=float)
        Q = self._levels.size

        self.z_mean, self.z_std = _fit_standardiser(Z)
        Zs = ((Z - self.z_mean) / self.z_std).astype(np.float32)

        dev = torch.device(self.device)
        X = torch.as_tensor(Zs, device=dev)
        yt = torch.as_tensor(y, device=dev).unsqueeze(-1)          # (n,1)
        levels = torch.as_tensor(self._levels, dtype=torch.float32, device=dev).view(1, -1)  # (1,Q)

        self._net = nn.Sequential(
            nn.Linear(d, int(self.hidden)), nn.ReLU(),
            nn.Linear(int(self.hidden), int(self.hidden)), nn.ReLU(),
            nn.Linear(int(self.hidden), Q),
        ).to(dev)
        opt = torch.optim.AdamW(self._net.parameters(), lr=float(self.lr), weight_decay=float(self.weight_decay))

        self._net.train()
        for _ in range(int(self.steps)):
            opt.zero_grad()
            pred = self._net(X)                     # (n,Q)
            err = yt - pred                         # (n,Q)
            loss = torch.mean(torch.maximum(levels * err, (levels - 1.0) * err))
            loss.backward()
            torch.nn.utils.clip_grad_norm_(self._net.parameters(), max_norm=float(self.clip_grad))
            opt.step()

        self.meta = {"kind": "quantile_runtime_head", "d": int(d), "quantiles": self._levels.tolist()}
        return self

    def _raw_quantiles(self, z: np.ndarray) -> np.ndarray:
        import torch
        zs = ((np.asarray(z, dtype=np.float32).reshape(1, -1) - self.z_mean) / self.z_std).astype(np.float32)
        dev = next(self._net.parameters()).device
        self._net.eval()
        with torch.no_grad():
            q = self._net(torch.as_tensor(zs, device=dev)).cpu().numpy().reshape(-1)
        return np.sort(q)  # enforce monotonicity (anti-crossing)

    def predict_quantiles(self, z: np.ndarray) -> Dict[float, float]:
        q = self._raw_quantiles(z)
        return {float(l): float(v) for l, v in zip(self._levels, q)}

    def predict(self, z: np.ndarray) -> Dict[str, float]:
        if self._net is None:
            raise RuntimeError("QuantileRuntimeHead not fit")
        q = self._raw_quantiles(z)
        lv = self._levels

        mu = float(np.interp(0.5, lv, q))
        # robust sigma: prefer the 16/84 interval (~1 std), else scale the widest available
        if lv.min() <= 0.16 and lv.max() >= 0.84:
            sigma = (np.interp(0.84, lv, q) - np.interp(0.16, lv, q)) / 2.0
        else:
            lo, hi = lv.min(), lv.max()
            from scipy.stats import norm
            z_span = norm.ppf(hi) - norm.ppf(lo)
            sigma = (q[-1] - q[0]) / max(z_span, 1e-6)

        return {
            "mu_log": float(np.clip(mu, -20.0, 20.0)),
            "sigma_log": _clip_sigma(sigma),
            "quantiles": {float(l): float(v) for l, v in zip(lv, q)},
            "quantile_levels": lv.tolist(),
        }

    def sample(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray:
        q = self._raw_quantiles(z)
        lv = self._levels
        u = rng.uniform(0.0, 1.0, size=int(n))
        logT = np.interp(u, lv, q)  # inverse-CDF; flat extrapolation beyond outer quantiles
        return _safe_exp(logT)


# -----------------------------------------------------------------------------
# GP runtime head: NNGP (Lee et al., 2018) or RBF  -- Tier 3 anchor
# -----------------------------------------------------------------------------

@dataclass
class GPRuntimeHead:
    """
    Exact GP regression on the shared embedding, predicting logT with a
    closed-form Gaussian predictive (epistemic via posterior variance +
    aleatoric via observation noise).

    kernel="nngp": the Neural Network Gaussian Process kernel of an L-layer
                   fully-connected ReLU network (Lee et al., 2018), i.e. the
                   arc-cosine recursion. This is the Tier-3 NNGP baseline
                   retargeted from cardinality to runtime.
    kernel="rbf":  standard squared-exponential kernel.
    """
    kernel: str = "nngp"
    noise_var: float = 1e-2
    refit_noise: bool = True

    # nngp params
    depth: int = 3
    sigma_w2: float = 1.6
    sigma_b2: float = 0.1

    # rbf params
    length_scale: float = 1.0
    kernel_var: float = 1.0

    # learned
    z_mean: Optional[np.ndarray] = None
    z_std: Optional[np.ndarray] = None
    Z_train: Optional[np.ndarray] = None
    L: Optional[np.ndarray] = None
    alpha: Optional[np.ndarray] = None
    y_mean: float = 0.0
    meta: Dict[str, Any] = None

    # ---- kernels ----
    def _rbf_gram(self, A: np.ndarray, B: np.ndarray) -> np.ndarray:
        d2 = np.sum((A[:, None, :] - B[None, :, :]) ** 2, axis=2)
        return float(self.kernel_var) * np.exp(-0.5 * d2 / (float(self.length_scale) ** 2 + 1e-12))

    def _rbf_diag(self, A: np.ndarray) -> np.ndarray:
        return np.full((A.shape[0],), float(self.kernel_var))

    def _nngp_gram(self, A: np.ndarray, B: np.ndarray) -> np.ndarray:
        d = A.shape[1]
        sw2, sb2 = float(self.sigma_w2), float(self.sigma_b2)
        Kab = sb2 + sw2 * (A @ B.T) / d
        Kaa = sb2 + sw2 * np.sum(A * A, axis=1) / d
        Kbb = sb2 + sw2 * np.sum(B * B, axis=1) / d
        for _ in range(int(self.depth)):
            denom = np.sqrt(np.outer(Kaa, Kbb)) + 1e-12
            c = np.clip(Kab / denom, -1.0, 1.0)
            theta = np.arccos(c)
            Kab = sb2 + sw2 / (2.0 * np.pi) * denom * (np.sin(theta) + (np.pi - theta) * np.cos(theta))
            Kaa = sb2 + sw2 * 0.5 * Kaa
            Kbb = sb2 + sw2 * 0.5 * Kbb
        return Kab

    def _nngp_diag(self, A: np.ndarray) -> np.ndarray:
        d = A.shape[1]
        sw2, sb2 = float(self.sigma_w2), float(self.sigma_b2)
        Kaa = sb2 + sw2 * np.sum(A * A, axis=1) / d
        for _ in range(int(self.depth)):
            Kaa = sb2 + sw2 * 0.5 * Kaa
        return Kaa

    def _gram(self, A: np.ndarray, B: np.ndarray) -> np.ndarray:
        return self._nngp_gram(A, B) if self.kernel == "nngp" else self._rbf_gram(A, B)

    def _diag(self, A: np.ndarray) -> np.ndarray:
        return self._nngp_diag(A) if self.kernel == "nngp" else self._rbf_diag(A)

    # ---- fit / predict ----
    def fit(self, Z: np.ndarray, logT_targets: np.ndarray) -> "GPRuntimeHead":
        Z = np.asarray(Z, dtype=float)
        y = np.asarray(logT_targets, dtype=float).reshape(-1)
        n = Z.shape[0]
        if n < 3:
            raise ValueError("Need at least 3 training samples for GPRuntimeHead")
        if self.kernel not in ("nngp", "rbf"):
            raise ValueError(f"kernel must be 'nngp' or 'rbf', got {self.kernel!r}")

        self.z_mean, self.z_std = _fit_standardiser(Z)
        Zs = (Z - self.z_mean) / self.z_std
        self.Z_train = Zs

        self.y_mean = float(np.mean(y))
        yc = y - self.y_mean

        K = self._gram(Zs, Zs)
        Ky = K + float(self.noise_var) * np.eye(n) + 1e-8 * np.eye(n)
        self.L = np.linalg.cholesky(Ky)
        v = np.linalg.solve(self.L, yc)
        self.alpha = np.linalg.solve(self.L.T, v)

        if self.refit_noise:
            resid = yc - K @ self.alpha
            self.noise_var = float(max(np.var(resid, ddof=1), 1e-6)) if n > 1 else float(self.noise_var)

        self.meta = {
            "kind": "gp_runtime_head", "kernel": self.kernel, "n_train": int(n),
            "noise_var": float(self.noise_var),
            "depth": int(self.depth) if self.kernel == "nngp" else None,
        }
        return self

    def predict(self, z: np.ndarray) -> Dict[str, float]:
        if self.alpha is None or self.L is None:
            raise RuntimeError("GPRuntimeHead not fit")
        zs = ((np.asarray(z, dtype=float).reshape(1, -1) - self.z_mean) / self.z_std)

        k_star = self._gram(zs, self.Z_train).reshape(-1)      # (n,)
        mu = float(k_star @ self.alpha) + self.y_mean

        v = np.linalg.solve(self.L, k_star)
        var_f = float(self._diag(zs)[0]) - float(v @ v)
        var = max(var_f, 0.0) + float(self.noise_var)          # epistemic + aleatoric
        sigma = _clip_sigma(np.sqrt(max(var, 1e-12)))

        return {
            "mu_log": float(np.clip(mu, -20.0, 20.0)),
            "sigma_log": sigma,
            "sigma_epistemic": _clip_sigma(np.sqrt(max(var_f, 0.0))),
            "sigma_aleatoric": _clip_sigma(np.sqrt(float(self.noise_var))),
        }

    def sample(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray:
        p = self.predict(z)
        logT = rng.normal(loc=p["mu_log"], scale=p["sigma_log"], size=int(n))
        return _safe_exp(logT)
