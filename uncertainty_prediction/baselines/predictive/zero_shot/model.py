"""
Zero-Shot Cost Model baseline (T1 point;
github.com/DataManagementLab/zero-shot-cost-estimation).

Hilprecht & Binnig (2022) represent a query plan as a graph of typed nodes and
run a message-passing GNN whose node features are *transferable* database
signals (so the model generalises zero-shot across databases). Here we keep the
plan-graph GNN and the bottom-up message passing; it is a point estimator, so
it fills only the point-error sheet.

Native-encoder note — the important lakehouse caveat: the original model's
transferability comes from featurising per-table / per-column *statistics*
(table cardinalities, column NDVs, data types, sampled histograms). Trino/Iceberg
plans as captured here do NOT carry those catalog statistics, so we cannot
reproduce the zero-shot *transfer* property. What we can reproduce is the
architecture: operator-typed embeddings + Trino cost estimates as node features,
message-passed to a plan embedding. This is an honest lakehouse adaptation, not
a faithful zero-shot-transfer model; flagged so results are read correctly.
"""

from __future__ import annotations

from typing import Dict, List

import numpy as np
import torch
import torch.nn as nn


class _ZeroShotGNN(nn.Module):
    def __init__(self, num_ops: int, cont_dim: int, *, emb_dim: int = 32, hidden: int = 128, n_layers: int = 3):
        super().__init__()
        self.n_layers = n_layers
        self.hidden = hidden
        self.op_emb = nn.Embedding(num_ops, emb_dim)
        self.in_proj = nn.Sequential(nn.Linear(emb_dim + cont_dim, hidden), nn.ReLU())
        # message: combine own state with aggregated child states
        self.msg = nn.ModuleList(
            [nn.Sequential(nn.Linear(2 * hidden, hidden), nn.ReLU()) for _ in range(n_layers)]
        )
        self.readout = nn.Sequential(nn.Linear(hidden, hidden), nn.ReLU(), nn.Linear(hidden, 1))

    def forward(self, graph: Dict) -> torch.Tensor:
        device = next(self.parameters()).device
        op_ids = torch.as_tensor(graph["op_ids"], dtype=torch.long, device=device)
        cont = torch.as_tensor(graph["cont"], dtype=torch.float32, device=device)
        children: List[List[int]] = graph["children"]
        post_order = graph["post_order"]

        h = self.in_proj(torch.cat([self.op_emb(op_ids), cont], dim=1))  # [n, hidden]
        for layer in range(self.n_layers):
            new_h = h.clone()
            for i in post_order:  # leaves -> root so children are already updated
                kids = children[i]
                agg = torch.stack([new_h[c] for c in kids], dim=0).mean(dim=0) if kids \
                    else torch.zeros(self.hidden, device=device)
                new_h[i] = self.msg[layer](torch.cat([h[i], agg], dim=0))
            h = new_h
        return self.readout(h[graph["root"]]).squeeze(-1)


class ZeroShotBaseline:
    def __init__(self, num_ops: int, cont_dim: int, *, hidden: int = 128, n_layers: int = 3, device: str = "cpu", seed: int = 42):
        torch.manual_seed(seed)
        self.device = device
        self.net = _ZeroShotGNN(num_ops, cont_dim, hidden=hidden, n_layers=n_layers).to(device)

    def fit(
        self,
        train_graphs: List[Dict],
        y_train_log,
        *,
        num_epochs: int = 100,
        lr: float = 1e-3,
        weight_decay: float = 1e-4,
        verbose: bool = False,
    ) -> "ZeroShotBaseline":
        y = torch.as_tensor(np.asarray(y_train_log, dtype=np.float32), device=self.device)
        opt = torch.optim.Adam(self.net.parameters(), lr=lr, weight_decay=weight_decay)
        loss_fn = nn.MSELoss()
        idx = np.arange(len(train_graphs))
        for epoch in range(num_epochs):
            self.net.train()
            np.random.shuffle(idx)
            losses = []
            for j in idx:
                opt.zero_grad()
                loss = loss_fn(self.net(train_graphs[j]), y[j])
                loss.backward()
                torch.nn.utils.clip_grad_norm_(self.net.parameters(), 5.0)
                opt.step()
                losses.append(loss.item())
            if verbose and (epoch + 1) % 20 == 0:
                print(f"epoch {epoch+1:03d} | mse={np.mean(losses):.4f}")
        return self

    @torch.no_grad()
    def predict_point_log(self, graphs: List[Dict]) -> np.ndarray:
        self.net.eval()
        return np.array([float(self.net(g).cpu()) for g in graphs], dtype=np.float64)
