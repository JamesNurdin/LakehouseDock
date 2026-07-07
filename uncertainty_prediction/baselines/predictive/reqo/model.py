"""
Reqo baseline (T4 named; github.com/BaomingChang/Reqo-on-PostgreSQL).

Reqo (Chang et al.) builds a tree-structured model with a bidirectional GNN over
the plan and produces cost estimates *with uncertainty* for robust query
optimisation. We reproduce the two ingredients that matter for this evaluation:

  1. a bidirectional tree encoder — a bottom-up (children -> parent) pass and a
     top-down (parent -> child) pass, whose per-node states are concatenated;
  2. a probabilistic head — a Gaussian (mu_log, log_sigma) over log-runtime,
     trained by Gaussian NLL, giving the "approximate probabilistic ML"
     uncertainty the roster attributes to Reqo.

The plan embedding is a mean-pool over final node states (order-invariant),
then the Gaussian head. Fills all four metric sheets.

Native-encoder note: Reqo's Postgres pipeline featurises operator cost/row
estimates and encoded predicates. The lakehouse provides operator identity +
Trino cost estimates via the shared `NodeGraphAdapter`; learned predicate
encodings are not available and are omitted (documented, not faked).
"""

from __future__ import annotations

from typing import Dict, List

import numpy as np
import torch
import torch.nn as nn

from uncertainty_prediction.baselines.predictive.common.mlp import mlp_gaussian_nll


class _ReqoEncoder(nn.Module):
    def __init__(self, num_ops: int, cont_dim: int, *, emb_dim: int = 32, hidden: int = 128,
                 log_sigma_min: float = -6.0, log_sigma_max: float = 3.0):
        super().__init__()
        self.hidden = hidden
        self.log_sigma_min = log_sigma_min
        self.log_sigma_max = log_sigma_max
        self.op_emb = nn.Embedding(num_ops, emb_dim)
        self.in_proj = nn.Sequential(nn.Linear(emb_dim + cont_dim, hidden), nn.ReLU())
        self.up = nn.GRUCell(hidden, hidden)     # bottom-up
        self.down = nn.GRUCell(hidden, hidden)   # top-down
        self.head = nn.Sequential(nn.Linear(2 * hidden, hidden), nn.ReLU())
        self.fc_mu = nn.Linear(hidden, 1)
        self.fc_ls = nn.Linear(hidden, 1)
        nn.init.constant_(self.fc_ls.bias, -0.5)

    def forward(self, graph: Dict):
        device = next(self.parameters()).device
        op_ids = torch.as_tensor(graph["op_ids"], dtype=torch.long, device=device)
        cont = torch.as_tensor(graph["cont"], dtype=torch.float32, device=device)
        children: List[List[int]] = graph["children"]
        post_order = graph["post_order"]
        n = cont.shape[0]

        x = self.in_proj(torch.cat([self.op_emb(op_ids), cont], dim=1))  # [n, hidden]

        # parent pointers
        parent = [-1] * n
        for i in range(n):
            for c in children[i]:
                parent[c] = i

        # bottom-up: message from mean of children states
        up = [None] * n
        for i in post_order:
            kids = children[i]
            msg = torch.stack([up[c] for c in kids], dim=0).mean(dim=0) if kids \
                else torch.zeros(self.hidden, device=device)
            up[i] = self.up(x[i].unsqueeze(0), msg.unsqueeze(0)).squeeze(0)

        # top-down: message from parent state (root -> leaves)
        down = [None] * n
        for i in reversed(post_order):
            p = parent[i]
            msg = down[p] if p >= 0 and down[p] is not None else torch.zeros(self.hidden, device=device)
            down[i] = self.down(x[i].unsqueeze(0), msg.unsqueeze(0)).squeeze(0)

        node_state = torch.stack(
            [torch.cat([up[i], down[i]], dim=0) for i in range(n)], dim=0
        )  # [n, 2*hidden]
        pooled = self.head(node_state.mean(dim=0))  # order-invariant plan embedding
        mu = self.fc_mu(pooled).squeeze(-1)
        log_sigma = torch.clamp(self.fc_ls(pooled).squeeze(-1), self.log_sigma_min, self.log_sigma_max)
        return mu, log_sigma


class ReqoBaseline:
    def __init__(self, num_ops: int, cont_dim: int, *, hidden: int = 128, device: str = "cpu", seed: int = 42):
        torch.manual_seed(seed)
        self.device = device
        self.net = _ReqoEncoder(num_ops, cont_dim, hidden=hidden).to(device)

    def fit(
        self,
        train_graphs: List[Dict],
        y_train_log,
        *,
        num_epochs: int = 100,
        lr: float = 1e-3,
        weight_decay: float = 1e-4,
        verbose: bool = False,
    ) -> "ReqoBaseline":
        y = torch.as_tensor(np.asarray(y_train_log, dtype=np.float32), device=self.device)
        opt = torch.optim.Adam(self.net.parameters(), lr=lr, weight_decay=weight_decay)
        idx = np.arange(len(train_graphs))
        for epoch in range(num_epochs):
            self.net.train()
            np.random.shuffle(idx)
            losses = []
            for j in idx:
                opt.zero_grad()
                mu, ls = self.net(train_graphs[j])
                loss = mlp_gaussian_nll(mu.reshape(1), ls.reshape(1), y[j].reshape(1))
                loss.backward()
                torch.nn.utils.clip_grad_norm_(self.net.parameters(), 5.0)
                opt.step()
                losses.append(loss.item())
            if verbose and (epoch + 1) % 20 == 0:
                print(f"epoch {epoch+1:03d} | nll={np.mean(losses):.4f}")
        return self

    @torch.no_grad()
    def predict_gaussian(self, graphs: List[Dict]) -> Dict[str, np.ndarray]:
        self.net.eval()
        mus, sigmas = [], []
        for g in graphs:
            mu, ls = self.net(g)
            mus.append(float(mu.cpu()))
            sigmas.append(float(torch.exp(ls).cpu()))
        return {
            "mu_log": np.asarray(mus, dtype=np.float64),
            "sigma_log": np.clip(np.asarray(sigmas, dtype=np.float64), 1e-9, None),
        }
