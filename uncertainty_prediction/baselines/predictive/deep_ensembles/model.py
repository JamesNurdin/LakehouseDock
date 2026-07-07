"""
Deep Ensembles baseline (T2 mechanism; also the roster stand-in for Fauce).

Lakshminarayanan et al. (2017): train M independently-initialised Gaussian
MLPs (each with its own mean+variance head, NLL loss) and treat the predictive
distribution as an equally-weighted mixture of Gaussians. The mixture mean and
variance (moment-matched to a single Gaussian in log space) are:

    mu*      = mean_m(mu_m)
    var*     = mean_m(sigma_m^2 + mu_m^2) - mu*^2

capturing both aleatoric (per-member sigma) and epistemic (disagreement) parts.
"""

from __future__ import annotations

from typing import Dict

import numpy as np
import torch

from uncertainty_prediction.baselines.predictive.common.mlp import (
    GaussianMLP,
    train_gaussian_mlp,
)


class DeepEnsemble:
    def __init__(
        self,
        in_dim: int,
        *,
        num_members: int = 5,
        hidden_dims=(256, 128),
        dropout: float = 0.1,
        device: str = "cpu",
        seed: int = 42,
    ):
        self.device = device
        self.seed = seed
        self.num_members = num_members
        self.hidden_dims = hidden_dims
        self.dropout = dropout
        self.members = []
        for m in range(num_members):
            torch.manual_seed(seed + m)  # distinct init per member
            self.members.append(GaussianMLP(in_dim, hidden_dims=hidden_dims, dropout=dropout))

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
    ) -> "DeepEnsemble":
        for m, net in enumerate(self.members):
            if verbose:
                print(f"[DeepEnsemble] training member {m+1}/{self.num_members}")
            self.members[m] = train_gaussian_mlp(
                net, X_train, y_train_log,
                num_epochs=num_epochs, lr=lr, weight_decay=weight_decay,
                batch_size=batch_size, device=self.device,
                seed=self.seed + m, verbose=verbose,
            )
        return self

    @torch.no_grad()
    def predict_gaussian(self, X) -> Dict[str, np.ndarray]:
        x = torch.as_tensor(np.asarray(X), dtype=torch.float32, device=self.device)
        mus, vars_ = [], []
        for net in self.members:
            net.eval()
            mu, log_sigma = net(x)
            mus.append(mu.cpu().numpy().reshape(-1))
            vars_.append(np.exp(2.0 * log_sigma.cpu().numpy().reshape(-1)))
        mus = np.stack(mus, axis=0)      # [M, N]
        vars_ = np.stack(vars_, axis=0)  # [M, N]

        mu_star = mus.mean(axis=0)
        var_star = (vars_ + mus ** 2).mean(axis=0) - mu_star ** 2
        return {
            "mu_log": mu_star,
            "sigma_log": np.sqrt(np.clip(var_star, 1e-12, None)),
            "member_mus_log": mus,
        }
