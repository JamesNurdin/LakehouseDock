"""
DACE baseline (T1 point; github.com/liang-zibo/DACE).

DACE — "A Database-Agnostic Cost Estimator" (Liang et al., ICDE 2024) — is a
point cost/latency estimator that *cites and builds on* the Zero-Shot Cost Model
code base, which makes it a natural third named baseline next to `zero_shot` and
`qppnet`. Where Zero-Shot message-passes over the plan graph and QPPNet composes
per-operator units bottom-up, DACE takes a third route:

  1. flatten the plan into a pre-order **node sequence**,
  2. run a single-head **Transformer encoder** over that sequence, where the
     self-attention is masked by *tree reachability* — a node may attend only to
     itself and its descendants (so the root attends to the whole plan),
  3. read out the root node through a small MLP with a **sigmoid runtime head**
     that predicts runtime as a fraction of a fitted `max_runtime`.

This adapter reuses the shared `NodeGraphAdapter` tensors (`build_graph_dataset`)
that QPPNet / Zero-Shot already consume — no new featureisation — and converts
each plan graph to DACE's (sequence, tree-mask) form on the fly.

Native-encoder notes (the lakehouse feature gaps, documented not faked):

  * Per-subplan supervision. The original DACE supervises *every* node against
    that operator's Postgres `Actual Total Time`, height-weighting the loss so
    sub-plans train together. Trino/Iceberg plans as captured here carry only a
    single whole-query runtime, not per-operator actual times, so we cannot
    supervise interior nodes. We keep DACE's Q-error log loss and sigmoid head
    but the loss mask collapses to the **root** (whole-query runtime). Same class
    of caveat the README already flags for Zero-Shot / QPPNet.

  * LoRA. DACE's linear layers are LoRA layers purely to enable its cross-database
    *fine-tuning / knowledge-integration* transfer story. This is a single
    lakehouse, so there is nothing to transfer from; we use plain `nn.Linear`.
    Swapping in `loralib` here would change nothing for one database.

  * Node features. DACE's node vector is one-hot(operator) ++ scaled numeric plan
    parameters. We keep that shape using the lakehouse operator vocabulary +
    standardised Trino cost estimates the shared adapter provides per node.

It is a *point* estimator, so it fills only the point-error sheet; CRPS /
interval / uncertainty sheets are n/a for Tier-1.
"""

from __future__ import annotations

from typing import Dict, List, Sequence, Tuple

import numpy as np
import torch
import torch.nn as nn


# --------------------------------------------------------------------------- #
# graph (NodeGraphAdapter tensors) -> DACE (node sequence, tree-mask) form
# --------------------------------------------------------------------------- #
def _preorder(root: int, children: Sequence[Sequence[int]]) -> List[int]:
    """Pre-order (root first) DFS over child edges; root lands at position 0."""
    order: List[int] = []
    stack = [root]
    while stack:
        node = stack.pop()
        order.append(node)
        for c in reversed(children[node]):
            stack.append(c)
    return order


def _descendants(children: Sequence[Sequence[int]], post_order: Sequence[int]) -> List[set]:
    """desc[i] = set of nodes in the subtree rooted at i, excluding i itself.

    post_order is leaves-first, so every child is finished before its parent.
    """
    n = len(children)
    desc: List[set] = [set() for _ in range(n)]
    for node in post_order:
        for c in children[node]:
            desc[node].add(c)
            desc[node] |= desc[c]
    return desc


def graph_to_dace(graph: Dict, num_ops: int) -> Tuple[np.ndarray, np.ndarray]:
    """Return (seq [L, num_ops + cont_dim], attn_mask [L, L] bool).

    attn_mask follows torch semantics: True == *disallowed*. A query node may
    attend to itself and to its descendants only (DACE's ancestor->descendant
    reachability mask); the root (position 0) therefore attends to every node.
    """
    op_ids = np.asarray(graph["op_ids"], dtype=np.int64)
    cont = np.asarray(graph["cont"], dtype=np.float32)
    children = graph["children"]
    root = graph["root"]

    order = _preorder(root, children)
    pos = {old: i for i, old in enumerate(order)}  # old node idx -> seq position
    n = len(order)

    # node vector = one-hot(op) ++ standardised continuous features, in pre-order
    one_hot = np.zeros((n, num_ops), dtype=np.float32)
    cont_seq = np.zeros((n, cont.shape[1]), dtype=np.float32)
    for i, old in enumerate(order):
        one_hot[i, int(op_ids[old])] = 1.0
        cont_seq[i] = cont[old]
    seq = np.concatenate([one_hot, cont_seq], axis=1)

    # tree-reachability attention mask (True = masked out)
    desc = _descendants(children, graph["post_order"])
    mask = np.ones((n, n), dtype=bool)
    for old in order:
        qi = pos[old]
        mask[qi, qi] = False  # a node can always attend to itself
        for d in desc[old]:
            mask[qi, pos[d]] = False  # ancestor -> descendant
    return seq, mask


# --------------------------------------------------------------------------- #
# DACE network (single-head Transformer encoder + sigmoid runtime head)
# --------------------------------------------------------------------------- #
class _DACE(nn.Module):
    def __init__(
        self,
        node_length: int,
        *,
        hidden: int = 128,
        mlp_dropout: float = 0.3,
        transformer_dropout: float = 0.2,
    ):
        super().__init__()
        self.node_length = node_length
        self.encoder = nn.TransformerEncoder(
            nn.TransformerEncoderLayer(
                d_model=node_length,
                dim_feedforward=hidden,
                nhead=1,
                batch_first=True,
                activation="gelu",
                dropout=transformer_dropout,
            ),
            num_layers=1,
            enable_nested_tensor=False,  # nhead=1 is DACE's design; avoids a noisy warning
        )
        # DACE's read-out MLP: node_length -> 128 -> 64 -> 1  (plain Linear; see
        # module docstring on why LoRA is dropped for a single database).
        self.mlp = nn.Sequential(
            nn.Linear(node_length, 128), nn.Dropout(mlp_dropout), nn.ReLU(),
            nn.Linear(128, 64), nn.Dropout(mlp_dropout), nn.ReLU(),
            nn.Linear(64, 1),
        )
        self.sigmoid = nn.Sigmoid()

    def forward(self, seq: torch.Tensor, attn_mask: torch.Tensor) -> torch.Tensor:
        """seq: [L, node_length], attn_mask: [L, L] bool -> root runtime frac in (0,1)."""
        x = seq.unsqueeze(0)  # [1, L, node_length]
        out = self.encoder(x, mask=attn_mask)  # [1, L, node_length]
        out = self.sigmoid(self.mlp(out))  # [1, L, 1] in (0, 1)
        return out[0, 0, 0]  # root (position 0): runtime as fraction of max_runtime


class DACEBaseline:
    """Point estimator with the roster's uniform structured-model API.

    Consumes the same `build_graph_dataset` graphs as QPPNet / Zero-Shot.
    """

    def __init__(
        self,
        num_ops: int,
        cont_dim: int,
        *,
        hidden: int = 128,
        device: str = "cpu",
        seed: int = 42,
    ):
        torch.manual_seed(seed)
        self.device = device
        self.num_ops = num_ops
        self.node_length = num_ops + cont_dim
        self.net = _DACE(self.node_length, hidden=hidden).to(device)
        self.max_runtime = 1.0  # fitted on the train split in .fit()

    def _prep(self, graph: Dict) -> Tuple[torch.Tensor, torch.Tensor]:
        seq_np, mask_np = graph_to_dace(graph, self.num_ops)
        seq = torch.as_tensor(seq_np, dtype=torch.float32, device=self.device)
        mask = torch.as_tensor(mask_np, dtype=torch.bool, device=self.device)
        return seq, mask

    def fit(
        self,
        train_graphs: List[Dict],
        y_train_log,
        *,
        num_epochs: int = 100,
        lr: float = 1e-3,
        weight_decay: float = 1e-4,
        headroom: float = 1.2,
        verbose: bool = False,
    ) -> "DACEBaseline":
        # DACE predicts runtime as a fraction of a fixed max_runtime via sigmoid;
        # fit that scale on the train split (headroom keeps the largest example
        # off the sigmoid's saturated tail).
        runtimes = np.exp(np.asarray(y_train_log, dtype=np.float64))
        self.max_runtime = float(runtimes.max()) * float(headroom)

        target_norm = torch.as_tensor(
            (runtimes / self.max_runtime).astype(np.float32), device=self.device
        )
        prepared = [self._prep(g) for g in train_graphs]

        opt = torch.optim.Adam(self.net.parameters(), lr=lr, weight_decay=weight_decay)
        eps = 1e-7
        idx = np.arange(len(prepared))
        for epoch in range(num_epochs):
            self.net.train()
            np.random.shuffle(idx)
            losses = []
            for j in idx:
                seq, mask = prepared[j]
                opt.zero_grad()
                est = self.net(seq, mask).clamp_min(eps)  # root runtime fraction
                tgt = target_norm[j].clamp_min(eps)
                # DACE Q-error log loss, root-supervised (see module docstring):
                # log(max(est/tgt, tgt/est, 1))
                q = torch.max(est / tgt, tgt / est)
                loss = torch.log(torch.where(q > 1, q, torch.ones_like(q)))
                loss.backward()
                torch.nn.utils.clip_grad_norm_(self.net.parameters(), 5.0)
                opt.step()
                losses.append(loss.item())
            if verbose and (epoch + 1) % 20 == 0:
                print(f"epoch {epoch+1:03d} | dace_loss={np.mean(losses):.4f}")
        return self

    @torch.no_grad()
    def predict_point_log(self, graphs: List[Dict]) -> np.ndarray:
        """Root runtime fraction -> runtime -> log-runtime (roster contract)."""
        self.net.eval()
        eps = 1e-7
        out = []
        for g in graphs:
            seq, mask = self._prep(g)
            frac = float(self.net(seq, mask).clamp_min(eps).cpu())
            out.append(np.log(frac * self.max_runtime))
        return np.array(out, dtype=np.float64)
