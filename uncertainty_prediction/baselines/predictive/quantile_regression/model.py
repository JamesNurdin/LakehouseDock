"""
Quantile Regression baseline (T2 mechanism; distribution-free).

A single MLP with one output per quantile level, trained with the pinball
(check) loss over a fixed quantile grid. Outputs are sorted at inference to
enforce non-crossing quantiles, giving a distribution-free predictive
description of log-runtime (no Gaussian assumption).

Native-encoder note: quantile regression is head-only; its encoder is a feature
table. We use the shared `PlanFeatureAdapter` lakehouse features.
"""

from __future__ import annotations

from typing import Dict, Sequence

import numpy as np
import torch
import torch.nn as nn

from uncertainty_prediction.baselines.predictive.common.metrics import QLEVELS_DEFAULT
from uncertainty_prediction.baselines.predictive.common.mlp import make_loaders


class _MultiQuantileMLP(nn.Module):
    def __init__(self, in_dim: int, n_q: int, hidden_dims=(256, 128), dropout: float = 0.1):
        super().__init__()
        dims = [in_dim, *hidden_dims]
        layers = []
        for a, b in zip(dims[:-1], dims[1:]):
            layers += [nn.Linear(a, b), nn.ReLU(), nn.Dropout(dropout)]
        self.body = nn.Sequential(*layers)
        self.head = nn.Linear(dims[-1], n_q)

    def forward(self, x):
        return self.head(self.body(x))  # [N, n_q]


def pinball_loss_torch(preds: torch.Tensor, target: torch.Tensor, levels: torch.Tensor) -> torch.Tensor:
    """preds [N, k], target [N], levels [k] -> mean pinball loss."""
    target = target.reshape(-1, 1)
    diff = target - preds                       # [N, k]
    loss = torch.maximum(levels * diff, (levels - 1.0) * diff)
    return loss.mean()


class QuantileRegression:
    def __init__(
        self,
        in_dim: int,
        *,
        qlevels: Sequence[float] = QLEVELS_DEFAULT,
        hidden_dims=(256, 128),
        dropout: float = 0.1,
        device: str = "cpu",
        seed: int = 42,
    ):
        torch.manual_seed(seed)
        self.qlevels = list(qlevels)
        self.device = device
        self.seed = seed
        self.net = _MultiQuantileMLP(in_dim, len(self.qlevels), hidden_dims=hidden_dims, dropout=dropout)

    def fit(
        self,
        X_train,
        y_train_log,
        *,
        num_epochs: int = 200,
        lr: float = 1e-3,
        weight_decay: float = 1e-4,
        batch_size: int = 64,
        verbose: bool = False,
    ) -> "QuantileRegression":
        self.net = self.net.to(self.device)
        levels = torch.tensor(self.qlevels, dtype=torch.float32, device=self.device)
        loader = make_loaders(X_train, y_train_log, batch_size=batch_size, seed=self.seed)
        opt = torch.optim.Adam(self.net.parameters(), lr=lr, weight_decay=weight_decay)
        for epoch in range(num_epochs):
            self.net.train()
            losses = []
            for xb, yb in loader:
                xb, yb = xb.to(self.device), yb.to(self.device)
                opt.zero_grad()
                loss = pinball_loss_torch(self.net(xb), yb, levels)
                loss.backward()
                torch.nn.utils.clip_grad_norm_(self.net.parameters(), 5.0)
                opt.step()
                losses.append(loss.item())
            if verbose and (epoch + 1) % 20 == 0:
                print(f"epoch {epoch+1:03d} | pinball={np.mean(losses):.4f}")
        return self

    @torch.no_grad()
    def predict_quantiles(self, X) -> np.ndarray:
        """Return [N, k] log-runtime quantiles, sorted to avoid crossing."""
        self.net.eval()
        x = torch.as_tensor(np.asarray(X), dtype=torch.float32, device=self.device)
        q = self.net(x).cpu().numpy()
        return np.sort(q, axis=1)

    def predict_gaussian(self, X) -> Dict[str, np.ndarray]:
        """
        Convenience Gaussian-ish summary (median as mu, half the 68% interval
        as sigma) so quantile output can also flow through the Gaussian path.
        Prefer `predict_quantiles` + `evaluate_quantile_predictions`.
        """
        Q = self.predict_quantiles(X)
        levels = np.asarray(self.qlevels)
        med = Q[:, int(np.argmin(np.abs(levels - 0.5)))]
        lo = Q[:, int(np.argmin(np.abs(levels - 0.16)))]
        hi = Q[:, int(np.argmin(np.abs(levels - 0.84)))]
        sigma = np.clip((hi - lo) / 2.0, 1e-9, None)
        return {"mu_log": med, "sigma_log": sigma}
