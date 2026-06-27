from dataclasses import dataclass
from typing import Any, Dict, Optional

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F

__all__ = [
    "TorchMLPHeteroRuntimeHead",
]

def _safe_exp(x: np.ndarray, *, max_x: float = 50.0) -> np.ndarray:
    x = np.asarray(x, dtype=float)
    return np.exp(np.clip(x, a_min=-max_x, a_max=max_x))


class _TorchHeteroRuntimeNet(nn.Module):
    def __init__(self, d_in: int, hidden: int):
        super().__init__()
        self.fc1 = nn.Linear(d_in, hidden)
        self.fc_mu = nn.Linear(hidden, 1)
        self.fc_ls = nn.Linear(hidden, 1)

        nn.init.constant_(self.fc_ls.bias, -0.5)

    def forward(self, z: torch.Tensor):
        h = F.relu(self.fc1(z))
        mu = self.fc_mu(h).squeeze(-1)
        log_sigma = self.fc_ls(h).squeeze(-1)
        return mu, log_sigma


@dataclass
class TorchMLPHeteroRuntimeHead:
    """
    PyTorch version of MLPHeteroRuntimeHead.

      logT ~ Normal(mu_log(z), sigma_log(z)^2)

    External API intentionally mirrors the numpy head:
      .fit(Z, logT_targets) -> self
      .predict(z) -> {"mu_log": float, "sigma_log": float}
      .sample(z, rng, n) -> runtime samples in seconds
    """
    hidden: int = 64
    lr: float = 1e-2
    steps: int = 3000
    weight_decay: float = 1e-4
    clip_grad: float = 5.0
    seed: int = 0

    log_sigma_min: float = -3.0
    log_sigma_max: float = 3.0
    eps_sigma: float = 1e-6

    loss_mode: str = "nll_mae"
    mae_weight: float = 0.25
    mse_weight: float = 0.0
    beta_nll: float = 0.5

    device: str = "cpu"

    model_: Optional[_TorchHeteroRuntimeNet] = None
    z_mean: Optional[np.ndarray] = None
    z_std: Optional[np.ndarray] = None
    meta: Dict[str, Any] = None

    def _set_seed(self):
        torch.manual_seed(int(self.seed))
        np.random.seed(int(self.seed))

    def _standardise_np(self, Z: np.ndarray) -> np.ndarray:
        if self.z_mean is None or self.z_std is None:
            raise RuntimeError("TorchMLPHeteroRuntimeHead not fit (standardisation missing)")
        return (Z - self.z_mean) / self.z_std

    def _gaussian_nll(self, mu: torch.Tensor, log_sigma: torch.Tensor, y: torch.Tensor) -> torch.Tensor:
        log_sigma = torch.clamp(log_sigma, self.log_sigma_min, self.log_sigma_max)
        var = torch.exp(2.0 * log_sigma).clamp_min(1e-12)
        return torch.mean(0.5 * ((y - mu) ** 2 / var + torch.log(var)))

    def _beta_gaussian_nll(
        self,
        mu: torch.Tensor,
        log_sigma: torch.Tensor,
        y: torch.Tensor,
        beta: float = 0.5,
    ) -> torch.Tensor:
        log_sigma = torch.clamp(log_sigma, self.log_sigma_min, self.log_sigma_max)
        var = torch.exp(2.0 * log_sigma).clamp_min(1e-12)
    
        nll = 0.5 * ((y - mu) ** 2 / var + torch.log(var))
        weight = var.detach() ** float(beta)
    
        return torch.mean(weight * nll)
    
    
    def _loss(self, mu: torch.Tensor, log_sigma: torch.Tensor, y: torch.Tensor) -> torch.Tensor:
        nll = self._gaussian_nll(mu, log_sigma, y)
        beta_nll = self._beta_gaussian_nll(mu, log_sigma, y, beta=self.beta_nll)
        mae = torch.mean(torch.abs(mu - y))
        mse = torch.mean((mu - y) ** 2)
    
        if self.loss_mode == "nll":
            return nll
    
        if self.loss_mode == "mae":
            return mae
    
        if self.loss_mode == "mse":
            return mse
    
        if self.loss_mode == "nll_mae":
            return nll + float(self.mae_weight) * mae
    
        if self.loss_mode == "nll_mse":
            return nll + float(self.mse_weight) * mse
    
        if self.loss_mode == "beta_nll":
            return beta_nll
    
        if self.loss_mode == "beta_nll_mae":
            return beta_nll + float(self.mae_weight) * mae
    
        raise ValueError(f"Unknown loss_mode: {self.loss_mode}")

    def fit(self, Z: np.ndarray, logT_targets: np.ndarray) -> "TorchMLPHeteroRuntimeHead":
        Z = np.asarray(Z, dtype=np.float32)
        y = np.asarray(logT_targets, dtype=np.float32).reshape(-1)

        n, d = Z.shape
        if n < 3:
            raise ValueError("Need at least 3 training samples for TorchMLPHeteroRuntimeHead")

        self._set_seed()

        self.z_mean = Z.mean(axis=0)
        self.z_std = Z.std(axis=0) + 1e-12
        Zs = self._standardise_np(Z).astype(np.float32)

        device = torch.device(self.device)
        X_t = torch.tensor(Zs, dtype=torch.float32, device=device)
        y_t = torch.tensor(y, dtype=torch.float32, device=device)

        self.model_ = _TorchHeteroRuntimeNet(d_in=d, hidden=int(self.hidden)).to(device)
        optimizer = torch.optim.AdamW(
            self.model_.parameters(),
            lr=float(self.lr),
            weight_decay=float(self.weight_decay),
        )

        self.model_.train()
        for _ in range(int(self.steps)):
            optimizer.zero_grad()

            mu, log_sigma = self.model_(X_t)
            loss = self._loss(mu, log_sigma, y_t)

            loss.backward()
            torch.nn.utils.clip_grad_norm_(self.model_.parameters(), max_norm=float(self.clip_grad))
            optimizer.step()

        self.model_.eval()
        with torch.no_grad():
            mu_hat, ls_hat = self.model_(X_t)
            ls_hat = torch.clamp(ls_hat, self.log_sigma_min, self.log_sigma_max)
            train_nll = float(self._gaussian_nll(mu_hat, ls_hat, y_t).item())

        self.meta = {
            "kind": "torch_mlp_hetero_runtime_head",
            "d": int(d),
            "hidden": int(self.hidden),
            "steps": int(self.steps),
            "train_nll": train_nll,
            "log_sigma_range": [float(self.log_sigma_min), float(self.log_sigma_max)],
            "device": str(device),
        }
        return self

    def predict(self, z: np.ndarray) -> Dict[str, float]:
        if self.model_ is None:
            raise RuntimeError("TorchMLPHeteroRuntimeHead not fit")

        z = np.asarray(z, dtype=np.float32).reshape(1, -1)
        zs = self._standardise_np(z).astype(np.float32)

        device = next(self.model_.parameters()).device
        z_t = torch.tensor(zs, dtype=torch.float32, device=device)

        self.model_.eval()
        with torch.no_grad():
            mu_log, log_sigma = self.model_(z_t)
            mu_log = float(torch.clamp(mu_log[0], -20.0, 20.0).item())
            log_sigma = float(torch.clamp(log_sigma[0], self.log_sigma_min, self.log_sigma_max).item())

        sigma_log = float(max(np.exp(log_sigma), self.eps_sigma))
        return {"mu_log": mu_log, "sigma_log": sigma_log}

    def sample(self, z: np.ndarray, *, rng: np.random.Generator, n: int) -> np.ndarray:
        p = self.predict(z)
        logT = rng.normal(loc=p["mu_log"], scale=p["sigma_log"], size=int(n))
        return _safe_exp(logT)