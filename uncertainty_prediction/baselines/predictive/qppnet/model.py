"""
QPPNet baseline (T1 point; github.com/rabbit721/QPPNet).

Plan-structured neural network (Marcus & Papaemmanouil 2019): every operator
type has its own small neural unit, and a query's prediction is built bottom-up
by feeding each node its features together with the composed outputs of its
children. It is a *point* estimator (no uncertainty), so it only populates the
point-error sheet; CRPS / interval / uncertainty sheets are n/a for Tier-1.

Native-encoder note: the original QPPNet unit inputs are Postgres per-operator
features (estimated rows, plan width, startup/total cost, and operator-specific
fields). The lakehouse exposes Trino cost estimates + operator identity + local
structure, which the shared `NodeGraphAdapter` provides per node; per-operator
units are preserved (one MLP per operator in the train vocabulary + an UNK unit).
"""

from __future__ import annotations

from typing import Dict, List

import numpy as np
import torch
import torch.nn as nn


class _OperatorUnit(nn.Module):
    def __init__(self, in_dim: int, hidden: int):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(in_dim, hidden), nn.ReLU(),
            nn.Linear(hidden, hidden), nn.ReLU(),
        )

    def forward(self, x):
        return self.net(x)


class _QPPNet(nn.Module):
    def __init__(self, num_ops: int, cont_dim: int, hidden: int = 128):
        super().__init__()
        self.hidden = hidden
        # one operator unit per operator id (per-operator specialisation, as in QPPNet)
        self.units = nn.ModuleList([_OperatorUnit(cont_dim + hidden, hidden) for _ in range(num_ops)])
        self.out = nn.Sequential(nn.Linear(hidden, hidden), nn.ReLU(), nn.Linear(hidden, 1))

    def forward(self, graph: Dict) -> torch.Tensor:
        device = next(self.parameters()).device
        op_ids = graph["op_ids"]
        cont = torch.as_tensor(graph["cont"], dtype=torch.float32, device=device)
        children: List[List[int]] = graph["children"]
        n = cont.shape[0]

        h = [None] * n
        for i in graph["post_order"]:
            kids = children[i]
            if kids:
                child_h = torch.stack([h[c] for c in kids], dim=0).mean(dim=0)
            else:
                child_h = torch.zeros(self.hidden, device=device)
            inp = torch.cat([cont[i], child_h], dim=0)
            h[i] = self.units[int(op_ids[i])](inp)
        return self.out(h[graph["root"]]).squeeze(-1)  # scalar log-runtime


class QPPNetBaseline:
    def __init__(self, num_ops: int, cont_dim: int, *, hidden: int = 128, device: str = "cpu", seed: int = 42):
        torch.manual_seed(seed)
        self.device = device
        self.net = _QPPNet(num_ops, cont_dim, hidden=hidden).to(device)

    def fit(
        self,
        train_graphs: List[Dict],
        y_train_log,
        *,
        num_epochs: int = 100,
        lr: float = 1e-3,
        weight_decay: float = 1e-4,
        verbose: bool = False,
    ) -> "QPPNetBaseline":
        y = torch.as_tensor(np.asarray(y_train_log, dtype=np.float32), device=self.device)
        opt = torch.optim.Adam(self.net.parameters(), lr=lr, weight_decay=weight_decay)
        loss_fn = nn.MSELoss()
        idx = np.arange(len(train_graphs))
        for epoch in range(num_epochs):
            self.net.train()
            np.random.shuffle(idx)
            losses = []
            opt.zero_grad()
            for step, j in enumerate(idx):
                pred = self.net(train_graphs[j])
                loss = loss_fn(pred, y[j])
                loss.backward()
                losses.append(loss.item())
                # simple per-example updates (small dataset)
                torch.nn.utils.clip_grad_norm_(self.net.parameters(), 5.0)
                opt.step()
                opt.zero_grad()
            if verbose and (epoch + 1) % 20 == 0:
                print(f"epoch {epoch+1:03d} | mse={np.mean(losses):.4f}")
        return self

    @torch.no_grad()
    def predict_point_log(self, graphs: List[Dict]) -> np.ndarray:
        self.net.eval()
        return np.array([float(self.net(g).cpu()) for g in graphs], dtype=np.float64)
