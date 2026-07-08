"""
Roq baseline (T4 named; github.com/M2oDA-Lab/Roq, arXiv:2401.15210).

Roq — "Robust Query Optimization" (Kamali et al., 2024) — is a *risk-aware* cost
model whose whole point is a calibrated predictive distribution, so it fills all
four metric sheets alongside Reqo. Two ingredients define it and are reproduced
here:

  1. A **dual encoder**. The native Roq combines
       * a query-graph GNN branch (`TransformerConv` over the join graph, then
         global mean+max pooling), and
       * a plan-tree TCNN branch (Neo/Bao binary tree convolution +
         dynamic/max pooling),
     concatenated before the output head. We keep this two-branch shape from the
     one structure the lakehouse actually carries — the plan DAG — running a
     **tree-convolution** branch (ordered, bottom-up, max-pooled) next to an
     order-invariant **graph-pooled** branch (message passing + mean/max pool).

  2. **Uncertainty decomposition** — the reason Roq exists. A heteroscedastic
     head emits (mu, variance); training minimises the Gaussian NLL Roq calls
     `aleatoric_loss` (variance parametrisation), giving the **aleatoric** term.
     At inference, **MC-dropout** (Roq's `LitMCdropoutModel`, `mc_iteration=10`)
     supplies the **epistemic** term. Roq's `comput_uncertainty` returns
     `Ud = mean_t(var_t)` (aleatoric) and `Um = var_t(mu_t)` (epistemic); we
     combine them by the law of total variance into the single Gaussian this
     roster scores: sigma_log = sqrt(Ud + Um). This aleatoric+epistemic split is
     exactly what separates Roq from Reqo (aleatoric-only).

Native-encoder notes (lakehouse feature gaps, documented not faked):

  * Query-graph branch inputs. Roq's GNN branch consumes the join graph with
    per-table statistics, join predicates and learned predicate encodings. Trino/
    Iceberg plans as captured here carry none of those, so this branch operates
    on the plan DAG + Trino cost estimates via the shared `NodeGraphAdapter` —
    the same catalog-statistics gap already flagged for Zero-Shot / Reqo. The
    global query-graph feature vector Roq concatenates is likewise unavailable
    and omitted.

  * BatchNorm -> none. Roq batches plans and uses BatchNorm1d. This roster trains
    structured models one plan at a time (faithful to tree structure), so we drop
    BatchNorm and rely on Dropout — which MC-dropout needs anyway.

  * Sigmoid mean head -> linear. Roq min-max normalises labels to [0,1] and uses
    a sigmoid mean head. This roster targets *log-runtime* (unbounded), so the
    mean head is linear and the variance head is Softplus (as in Roq).
"""

from __future__ import annotations

import math
from typing import Dict, List, Tuple

import numpy as np
import torch
import torch.nn as nn


def _roq_gaussian_nll(mu: torch.Tensor, var: torch.Tensor, y: torch.Tensor, eps: float = 1e-4) -> torch.Tensor:
    """Roq's `aleatoric_loss`: 0.5 * ( (mu-y)^2 / var + log var + log 2pi ).

    `var` is the (positive) variance head output, matching Roq's parametrisation
    where the std layer feeds this term directly (softplus -> variance).
    """
    se = (mu - y) ** 2
    return 0.5 * (se / (var + eps) + torch.log(var + eps) + math.log(2.0 * math.pi))


class _RoqNet(nn.Module):
    def __init__(
        self,
        num_ops: int,
        cont_dim: int,
        *,
        emb_dim: int = 32,
        hidden: int = 128,
        tree_layers: int = 2,
        graph_layers: int = 2,
        dropout: float = 0.1,
        var_min: float = 1e-4,
        var_max: float = 50.0,
    ):
        super().__init__()
        self.hidden = hidden
        self.var_min = var_min
        self.var_max = var_max
        self.op_emb = nn.Embedding(num_ops, emb_dim)
        self.in_proj = nn.Sequential(nn.Linear(emb_dim + cont_dim, hidden), nn.ReLU())

        # --- plan-tree TCNN branch: local (node ++ mean-children) convolutions ---
        self.tree_convs = nn.ModuleList(
            [nn.Sequential(nn.Linear(2 * hidden, hidden), nn.ReLU()) for _ in range(tree_layers)]
        )

        # --- query-graph GNN branch: undirected message passing, mean+max pooled ---
        self.graph_convs = nn.ModuleList(
            [nn.Sequential(nn.Linear(2 * hidden, hidden), nn.ReLU()) for _ in range(graph_layers)]
        )
        self.graph_out = nn.Sequential(nn.Linear(2 * hidden, hidden), nn.ReLU())  # mean++max -> hidden

        # --- fusion + heads (dropout kept live for MC-dropout epistemic term) ---
        self.final_mlp = nn.Sequential(
            nn.Linear(2 * hidden, hidden), nn.ReLU(), nn.Dropout(dropout),
            nn.Linear(hidden, hidden), nn.ReLU(), nn.Dropout(dropout),
        )
        self.mean_head = nn.Sequential(nn.Linear(hidden, 32), nn.ReLU(), nn.Dropout(dropout), nn.Linear(32, 1))
        self.var_head = nn.Sequential(nn.Linear(hidden, 32), nn.ReLU(), nn.Dropout(dropout), nn.Linear(32, 1), nn.Softplus())

    def _node_encodings(self, graph: Dict) -> Tuple[torch.Tensor, List[List[int]], List[List[int]], List[int]]:
        device = next(self.parameters()).device
        op_ids = torch.as_tensor(graph["op_ids"], dtype=torch.long, device=device)
        cont = torch.as_tensor(graph["cont"], dtype=torch.float32, device=device)
        x = self.in_proj(torch.cat([self.op_emb(op_ids), cont], dim=1))  # [n, hidden]
        children: List[List[int]] = graph["children"]
        n = cont.shape[0]
        # undirected neighbours (children ++ parent) for the graph branch
        neigh: List[List[int]] = [list(children[i]) for i in range(n)]
        for i in range(n):
            for c in children[i]:
                neigh[c].append(i)
        return x, children, neigh, graph["post_order"]

    def _tree_branch(self, x: torch.Tensor, children: List[List[int]]) -> torch.Tensor:
        device = x.device
        n = x.shape[0]
        h = x
        for conv in self.tree_convs:
            child_mean = torch.stack(
                [torch.stack([h[c] for c in children[i]], 0).mean(0) if children[i]
                 else torch.zeros(self.hidden, device=device) for i in range(n)],
                dim=0,
            )
            h = conv(torch.cat([h, child_mean], dim=1))
        return h.max(dim=0).values  # DynamicPooling (max over nodes)

    def _graph_branch(self, x: torch.Tensor, neigh: List[List[int]]) -> torch.Tensor:
        device = x.device
        n = x.shape[0]
        h = x
        for conv in self.graph_convs:
            nbr_mean = torch.stack(
                [torch.stack([h[j] for j in neigh[i]], 0).mean(0) if neigh[i]
                 else torch.zeros(self.hidden, device=device) for i in range(n)],
                dim=0,
            )
            h = conv(torch.cat([h, nbr_mean], dim=1))
        pooled = torch.cat([h.mean(dim=0), h.max(dim=0).values], dim=0)  # gap ++ gmp
        return self.graph_out(pooled)

    def forward(self, graph: Dict) -> Tuple[torch.Tensor, torch.Tensor]:
        x, children, neigh, _ = self._node_encodings(graph)
        tcnn_out = self._tree_branch(x, children)          # [hidden]
        gcnn_out = self._graph_branch(x, neigh)            # [hidden]
        fused = self.final_mlp(torch.cat([tcnn_out, gcnn_out], dim=0))
        mu = self.mean_head(fused).squeeze(-1)
        var = self.var_head(fused).squeeze(-1).clamp(self.var_min, self.var_max)
        return mu, var


class RoqBaseline:
    """Aleatoric+epistemic Gaussian estimator with the roster's structured API.

    Consumes the same `build_graph_dataset` graphs as QPPNet / Zero-Shot / Reqo.
    """

    def __init__(self, num_ops: int, cont_dim: int, *, hidden: int = 128, dropout: float = 0.1,
                 mc_samples: int = 10, device: str = "cpu", seed: int = 42):
        torch.manual_seed(seed)
        self.device = device
        self.mc_samples = mc_samples
        self.net = _RoqNet(num_ops, cont_dim, hidden=hidden, dropout=dropout).to(device)

    def fit(
        self,
        train_graphs: List[Dict],
        y_train_log,
        *,
        num_epochs: int = 100,
        lr: float = 1e-3,
        weight_decay: float = 1e-4,
        verbose: bool = False,
    ) -> "RoqBaseline":
        y = torch.as_tensor(np.asarray(y_train_log, dtype=np.float32), device=self.device)
        opt = torch.optim.AdamW(self.net.parameters(), lr=lr, weight_decay=weight_decay)
        idx = np.arange(len(train_graphs))
        for epoch in range(num_epochs):
            self.net.train()
            np.random.shuffle(idx)
            losses = []
            for j in idx:
                opt.zero_grad()
                mu, var = self.net(train_graphs[j])
                loss = _roq_gaussian_nll(mu.reshape(1), var.reshape(1), y[j].reshape(1)).mean()
                loss.backward()
                torch.nn.utils.clip_grad_norm_(self.net.parameters(), 5.0)
                opt.step()
                losses.append(loss.item())
            if verbose and (epoch + 1) % 20 == 0:
                print(f"epoch {epoch+1:03d} | nll={np.mean(losses):.4f}")
        return self

    def _enable_mc_dropout(self) -> None:
        """Eval mode everywhere, but Dropout layers active (Roq's LitMCdropoutModel)."""
        self.net.eval()
        for m in self.net.modules():
            if isinstance(m, nn.Dropout):
                m.train(True)

    @torch.no_grad()
    def predict_gaussian(self, graphs: List[Dict]) -> Dict[str, np.ndarray]:
        """MC-dropout sampling -> aleatoric (mean var) + epistemic (var of mu).

        Reproduces Roq's `comput_uncertainty`: Ud = mean_t(var_t),
        Um = var_t(mu_t); total variance = Ud + Um (law of total variance).
        """
        self._enable_mc_dropout()
        mus = np.zeros((self.mc_samples, len(graphs)), dtype=np.float64)
        vars_ = np.zeros((self.mc_samples, len(graphs)), dtype=np.float64)
        for t in range(self.mc_samples):
            for i, g in enumerate(graphs):
                mu, var = self.net(g)
                mus[t, i] = float(mu.cpu())
                vars_[t, i] = float(var.cpu())

        mu_log = mus.mean(axis=0)                 # predictive mean
        aleatoric = vars_.mean(axis=0)            # Ud
        epistemic = mus.var(axis=0)               # Um
        sigma_log = np.sqrt(np.clip(aleatoric + epistemic, 1e-18, None))
        return {
            "mu_log": mu_log,
            "sigma_log": np.clip(sigma_log, 1e-9, None),
            "aleatoric_var": aleatoric,
            "epistemic_var": epistemic,
        }
