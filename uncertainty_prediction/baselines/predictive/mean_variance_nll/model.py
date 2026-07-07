"""
Mean-Variance NLL baseline (T2 mechanism).

Canonical 2-output Gaussian head: a single network predicts both the mean and
the variance of log-runtime and is trained by minimising the Gaussian negative
log-likelihood (Nix & Weigend 1994; the standard aleatoric-uncertainty head).

Native-encoder note: the mechanism is encoder-agnostic. Here it consumes the
shared lakehouse plan features (`PlanFeatureAdapter`), which is the honest
lakehouse analogue of the tabular plan features these heads use over Postgres.
"""

from __future__ import annotations

from typing import Dict

import numpy as np
import torch

from uncertainty_prediction.baselines.predictive.common.mlp import (
    GaussianMLP,
    train_gaussian_mlp,
)


class MeanVarianceNLL:
    def __init__(
        self,
        in_dim: int,
        *,
        hidden_dims=(256, 128),
        dropout: float = 0.1,
        device: str = "cpu",
        seed: int = 42,
    ):
        torch.manual_seed(seed)
        self.device = device
        self.seed = seed
        self.net = GaussianMLP(in_dim, hidden_dims=hidden_dims, dropout=dropout)

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
    ) -> "MeanVarianceNLL":
        self.net = train_gaussian_mlp(
            self.net, X_train, y_train_log,
            num_epochs=num_epochs, lr=lr, weight_decay=weight_decay,
            batch_size=batch_size, device=self.device, seed=self.seed, verbose=verbose,
        )
        return self

    @torch.no_grad()
    def predict_gaussian(self, X) -> Dict[str, np.ndarray]:
        """Return (mu_log, sigma_log) for a Gaussian over log-runtime."""
        self.net.eval()
        x = torch.as_tensor(np.asarray(X), dtype=torch.float32, device=self.device)
        mu, log_sigma = self.net(x)
        return {
            "mu_log": mu.cpu().numpy().reshape(-1),
            "sigma_log": torch.exp(log_sigma).cpu().numpy().reshape(-1),
        }
