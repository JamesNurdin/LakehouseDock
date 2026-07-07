"""
MC-Dropout baseline (T2 mechanism; also the roster stand-in for HyperQO).

Gal & Ghahramani (2016): keep dropout active at test time and average many
stochastic forward passes to approximate the posterior predictive. Epistemic
uncertainty comes from the spread across passes; the network's own log_sigma
head contributes the aleatoric part, so the total predictive variance is

    var_total = var_across_passes(mu) + mean_across_passes(sigma^2)

which is then moment-matched to a Gaussian in log-runtime space.
"""

from __future__ import annotations

from typing import Dict

import numpy as np
import torch
import torch.nn as nn

from uncertainty_prediction.baselines.predictive.common.mlp import (
    GaussianMLP,
    train_gaussian_mlp,
)


class MCDropout:
    def __init__(
        self,
        in_dim: int,
        *,
        hidden_dims=(256, 128),
        dropout: float = 0.2,
        num_samples: int = 100,
        device: str = "cpu",
        seed: int = 42,
    ):
        torch.manual_seed(seed)
        self.device = device
        self.seed = seed
        self.num_samples = num_samples
        # dropout must be > 0 for MC-Dropout to yield epistemic spread
        self.net = GaussianMLP(in_dim, hidden_dims=hidden_dims, dropout=max(dropout, 0.05))

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
    ) -> "MCDropout":
        self.net = train_gaussian_mlp(
            self.net, X_train, y_train_log,
            num_epochs=num_epochs, lr=lr, weight_decay=weight_decay,
            batch_size=batch_size, device=self.device, seed=self.seed, verbose=verbose,
        )
        return self

    @staticmethod
    def _enable_dropout(model: nn.Module):
        for m in model.modules():
            if isinstance(m, nn.Dropout):
                m.train()

    @torch.no_grad()
    def predict_gaussian(self, X, *, num_samples: int | None = None) -> Dict[str, np.ndarray]:
        S = num_samples or self.num_samples
        self.net.eval()
        self._enable_dropout(self.net)  # dropout ON, everything else in eval

        x = torch.as_tensor(np.asarray(X), dtype=torch.float32, device=self.device)
        mus, vars_ = [], []
        for _ in range(S):
            mu, log_sigma = self.net(x)
            mus.append(mu.cpu().numpy().reshape(-1))
            vars_.append(np.exp(2.0 * log_sigma.cpu().numpy().reshape(-1)))
        mus = np.stack(mus, axis=0)      # [S, N]
        vars_ = np.stack(vars_, axis=0)  # [S, N]

        mu_mean = mus.mean(axis=0)
        var_total = mus.var(axis=0) + vars_.mean(axis=0)
        return {
            "mu_log": mu_mean,
            "sigma_log": np.sqrt(np.clip(var_total, 1e-12, None)),
            "samples_log": mus,  # per-pass means, for optional sample CRPS
        }
