from __future__ import annotations

import torch
import torch.nn as nn
import torch.nn.functional as F


COND_KIND_PAD = 0
COND_KIND_LEAF = 1
COND_KIND_AND = 2
COND_KIND_OR = 3


class TPoolRuntimeRegressor(nn.Module):
    """
    TPool-style runtime regressor for the updated Trino TLSTM/TPool data pipeline.

    Expected inputs
    ---------------
    operators           : [L, N, operator_dim]
    extra_infos         : [L, N, extra_dim]

    condition1_feats    : [L, N, T, condition_op_dim]
    condition1_mapping  : [L, N, T, 2]
    condition1_kinds    : [L, N, T]

    condition2_feats    : [L, N, T, condition_op_dim]
    condition2_mapping  : [L, N, T, 2]
    condition2_kinds    : [L, N, T]

    samples             : [L, N, sample_dim]
    condition_masks     : [L, N, 1]
    mapping             : [L, N, 2]
    """

    def __init__(
        self,
        operator_dim: int,
        extra_dim: int,
        condition_op_dim: int,
        sample_dim: int,
        *,
        hidden_dim: int = 128,
        hid_dim: int = 256,
        head_dim: int = 256,
    ):
        super().__init__()

        self.operator_dim = operator_dim
        self.extra_dim = extra_dim
        self.condition_op_dim = condition_op_dim
        self.sample_dim = sample_dim
        self.hidden_dim = hidden_dim
        self.hid_dim = hid_dim

        # leaf predicate projection
        self.condition_proj = nn.Linear(condition_op_dim, hid_dim)
        self.batch_norm1 = nn.BatchNorm1d(hid_dim)

        # sample branch
        self.sample_mlp = nn.Linear(sample_dim, hid_dim)

        # plan representation LSTM, same spirit as TLSTM
        lstm2_input_dim = operator_dim + extra_dim + 2 * hid_dim
        self.lstm2 = nn.LSTM(lstm2_input_dim, hidden_dim, batch_first=True)
        self.batch_norm2 = nn.BatchNorm1d(hidden_dim)

        # runtime head
        self.head_fc1 = nn.Linear(hidden_dim, head_dim)
        self.batch_norm3 = nn.BatchNorm1d(head_dim)
        self.head_fc2 = nn.Linear(head_dim, head_dim)
        self.out_fc = nn.Linear(head_dim, 1)

    def init_hidden(self, hidden_dim: int, batch_size: int, device: torch.device):
        return (
            torch.zeros(1, batch_size, hidden_dim, device=device),
            torch.zeros(1, batch_size, hidden_dim, device=device),
        )

    def _compose_condition_tree(
        self,
        feats: torch.Tensor,
        mapping: torch.Tensor,
        kinds: torch.Tensor,
    ) -> torch.Tensor:
        """
        feats   : [M, T, D]
        mapping : [M, T, 2]
        kinds   : [M, T]
    
        returns : [M, hid_dim]
        """
        device = feats.device
        M, T, _ = feats.shape
    
        base_rep = F.relu(self.condition_proj(feats))  # [M, T, H]
    
        # store node reps as a python list to avoid in-place writes on autograd tensors
        reps = [base_rep[:, t, :] for t in range(T)]
    
        for t in reversed(range(T)):
            kind_t = kinds[:, t]         # [M]
            child_idx = mapping[:, t, :] # [M, 2]
    
            left_idx = child_idx[:, 0]
            right_idx = child_idx[:, 1]
    
            zero_rep = torch.zeros(M, self.hid_dim, device=device)
    
            def gather_rep(idx_tensor):
                gathered = []
                for m in range(M):
                    idx = int(idx_tensor[m].item())
                    if idx == 0:
                        gathered.append(zero_rep[m])
                    else:
                        gathered.append(reps[idx - 1][m])
                return torch.stack(gathered, dim=0)
    
            left_rep = gather_rep(left_idx)
            right_rep = gather_rep(right_idx)
    
            current_rep = reps[t]
    
            is_leaf = (kind_t == COND_KIND_LEAF).unsqueeze(1)
            is_and = (kind_t == COND_KIND_AND).unsqueeze(1)
            is_or = (kind_t == COND_KIND_OR).unsqueeze(1)
    
            and_rep = torch.minimum(left_rep, right_rep)
            or_rep = torch.maximum(left_rep, right_rep)
    
            new_rep = torch.where(
                is_leaf,
                current_rep,
                torch.where(
                    is_and,
                    and_rep,
                    torch.where(is_or, or_rep, current_rep),
                ),
            )
    
            reps[t] = new_rep
    
        return reps[0]
    
    def forward(
        self,
        operators: torch.Tensor,
        extra_infos: torch.Tensor,
        condition1_feats: torch.Tensor,
        condition1_mapping: torch.Tensor,
        condition1_kinds: torch.Tensor,
        condition2_feats: torch.Tensor,
        condition2_mapping: torch.Tensor,
        condition2_kinds: torch.Tensor,
        samples: torch.Tensor,
        condition_masks: torch.Tensor,
        mapping: torch.Tensor,
    ) -> torch.Tensor:
        device = operators.device

        # infer merged batch size from non-zero roots at top level
        batch_size = 0
        for i in range(operators.size(1)):
            if operators[0, i].sum() != 0:
                batch_size += 1
            else:
                break

        num_level = operators.size(0)
        num_node_per_level = operators.size(1)

        # flatten [L, N, ...] -> [L*N, ...] for condition-tree encoding
        cond1_roots = self._compose_condition_tree(
            condition1_feats.view(num_level * num_node_per_level,
                                  condition1_feats.size(2),
                                  condition1_feats.size(3)),
            condition1_mapping.view(num_level * num_node_per_level,
                                    condition1_mapping.size(2),
                                    condition1_mapping.size(3)),
            condition1_kinds.view(num_level * num_node_per_level,
                                  condition1_kinds.size(2)),
        )

        cond2_roots = self._compose_condition_tree(
            condition2_feats.view(num_level * num_node_per_level,
                                  condition2_feats.size(2),
                                  condition2_feats.size(3)),
            condition2_mapping.view(num_level * num_node_per_level,
                                    condition2_mapping.size(2),
                                    condition2_mapping.size(3)),
            condition2_kinds.view(num_level * num_node_per_level,
                                  condition2_kinds.size(2)),
        )

        cond_output = 0.5 * (cond1_roots + cond2_roots)
        cond_output = self.batch_norm1(cond_output).view(num_level, num_node_per_level, -1)

        # sample branch
        sample_output = F.relu(self.sample_mlp(samples))
        sample_output = sample_output * condition_masks

        # node-level input to plan representation layer
        out = torch.cat((operators, extra_infos, cond_output, sample_output), dim=2)

        # bottom-up plan representation, same as TLSTM variant
        hidden = self.init_hidden(self.hidden_dim, num_node_per_level, device)
        last_level = out[num_level - 1].view(num_node_per_level, 1, -1)
        _, (hid, cid) = self.lstm2(last_level, hidden)

        mapping = mapping.long()

        for idx in reversed(range(0, num_level - 1)):
            mapp_left = mapping[idx][:, 0]
            mapp_right = mapping[idx][:, 1]

            zero_h = torch.zeros_like(hid)[:, 0].unsqueeze(1)
            next_hid = torch.cat((zero_h, hid), dim=1)

            zero_c = torch.zeros_like(cid)[:, 0].unsqueeze(1)
            next_cid = torch.cat((zero_c, cid), dim=1)

            hid_left = torch.index_select(next_hid, 1, mapp_left)
            cid_left = torch.index_select(next_cid, 1, mapp_left)
            hid_right = torch.index_select(next_hid, 1, mapp_right)
            cid_right = torch.index_select(next_cid, 1, mapp_right)

            hid = 0.5 * (hid_left + hid_right)
            cid = 0.5 * (cid_left + cid_right)

            current_level = out[idx].view(num_node_per_level, 1, -1)
            _, (hid, cid) = self.lstm2(current_level, (hid, cid))

        output = hid[0]
        output = output[0:batch_size]
        output = self.batch_norm2(output)

        h = F.relu(self.head_fc1(output))
        h = self.batch_norm3(h)
        h = F.relu(self.head_fc2(h))
        out = torch.sigmoid(self.out_fc(h))

        return out