"""
Shared MLP backbone for the feature-based uncertainty heads.

Mean-Variance NLL, MC-Dropout and Deep Ensembles all reuse this small
Gaussian MLP; they differ only in how uncertainty is produced at inference:

  - Mean-Variance NLL : a single net's learned log_sigma head (aleatoric)
  - MC-Dropout        : dropout left ON at test, many stochastic passes (epistemic)
  - Deep Ensembles    : several independently-initialised nets, mixture moments
"""

from __future__ import annotations

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F


class GaussianMLP(nn.Module):
    """
    MLP mapping standardised plan features -> (mu_log, log_sigma) for a
    Gaussian over log-runtime.

    Dropout is applied after each hidden activation; keep it > 0 for the
    MC-Dropout baseline and it is harmless (acts as regulariser) for the others.
    """

    def __init__(
        self,
        in_dim: int,
        *,
        hidden_dims=(256, 128),
        dropout: float = 0.1,
        log_sigma_min: float = -6.0,
        log_sigma_max: float = 3.0,
    ):
        super().__init__()
        self.log_sigma_min = log_sigma_min
        self.log_sigma_max = log_sigma_max
        self.dropout_p = dropout

        dims = [in_dim, *hidden_dims]
        layers = []
        for a, b in zip(dims[:-1], dims[1:]):
            layers += [nn.Linear(a, b), nn.ReLU(), nn.Dropout(dropout)]
        self.body = nn.Sequential(*layers)

        self.fc_mu = nn.Linear(dims[-1], 1)
        self.fc_ls = nn.Linear(dims[-1], 1)
        nn.init.constant_(self.fc_ls.bias, -0.5)

    def forward(self, x: torch.Tensor):
        h = self.body(x)
        mu = self.fc_mu(h).squeeze(-1)
        log_sigma = self.fc_ls(h).squeeze(-1)
        log_sigma = torch.clamp(log_sigma, self.log_sigma_min, self.log_sigma_max)
        return mu, log_sigma


def mlp_gaussian_nll(
    mu: torch.Tensor,
    log_sigma: torch.Tensor,
    target: torch.Tensor,
    *,
    reduction: str = "mean",
) -> torch.Tensor:
    """Gaussian NLL for y ~ Normal(mu, exp(2*log_sigma))."""
    target = target.reshape(-1)
    mu = mu.reshape(-1)
    log_sigma = log_sigma.reshape(-1)
    var = torch.exp(2.0 * log_sigma).clamp_min(1e-12)
    loss = 0.5 * ((target - mu) ** 2 / var + torch.log(var))
    if reduction == "none":
        return loss
    if reduction == "sum":
        return loss.sum()
    if reduction == "mean":
        return loss.mean()
    raise ValueError(f"Unknown reduction: {reduction}")


def make_loaders(X_train, y_train_log, *, batch_size=64, seed=42, device="cpu"):
    """Simple tensor DataLoader for feature-based training."""
    from torch.utils.data import DataLoader, TensorDataset

    g = torch.Generator()
    g.manual_seed(seed)
    ds = TensorDataset(
        torch.as_tensor(X_train, dtype=torch.float32),
        torch.as_tensor(y_train_log, dtype=torch.float32),
    )
    return DataLoader(ds, batch_size=batch_size, shuffle=True, generator=g)


def train_gaussian_mlp(
    model: GaussianMLP,
    X_train,
    y_train_log,
    *,
    num_epochs: int = 200,
    lr: float = 1e-3,
    weight_decay: float = 1e-4,
    batch_size: int = 64,
    device: str = "cpu",
    seed: int = 42,
    verbose: bool = False,
) -> GaussianMLP:
    """Train a single GaussianMLP with Gaussian NLL. Returns the model."""
    model = model.to(device)
    loader = make_loaders(X_train, y_train_log, batch_size=batch_size, seed=seed)
    opt = torch.optim.Adam(model.parameters(), lr=lr, weight_decay=weight_decay)
    for epoch in range(num_epochs):
        model.train()
        losses = []
        for xb, yb in loader:
            xb, yb = xb.to(device), yb.to(device)
            opt.zero_grad()
            mu, ls = model(xb)
            loss = mlp_gaussian_nll(mu, ls, yb)
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), 5.0)
            opt.step()
            losses.append(loss.item())
        if verbose and (epoch + 1) % 20 == 0:
            print(f"epoch {epoch+1:03d} | nll={np.mean(losses):.4f}")
    return model
