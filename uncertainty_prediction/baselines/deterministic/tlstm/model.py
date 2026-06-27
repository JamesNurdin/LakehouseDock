from __future__ import annotations

import torch
import torch.nn as nn
import torch.nn.functional as F


class TLSTMRuntimeRegressor(nn.Module):
    """
    Trino-adapted TLSTM model, closely following the exported notebook structure.

    Expected input shapes
    ---------------------
    operators      : [L, N, operator_dim]
    extra_infos    : [L, N, extra_dim]
    condition1s    : [L, N, C, condition_op_dim]
    condition2s    : [L, N, C, condition_op_dim]
    samples        : [L, N, sample_dim]
    condition_masks: [L, N, 1]
    mapping        : [L, N, 2]

    where:
      L = number of levels
      N = max nodes per level
      C = max condition tokens per node
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

        # condition sequence encoder (shared across condition1 and condition2)
        self.lstm1 = nn.LSTM(condition_op_dim, hidden_dim, batch_first=True)
        self.condition_mlp = nn.Linear(hidden_dim, hid_dim)
        self.batch_norm1 = nn.BatchNorm1d(hid_dim)

        # sample branch
        self.sample_mlp = nn.Linear(sample_dim, hid_dim)

        # bottom-up representation LSTM
        lstm2_input_dim = operator_dim + extra_dim + 2 * hid_dim
        self.lstm2 = nn.LSTM(lstm2_input_dim, hidden_dim, batch_first=True)
        self.batch_norm2 = nn.BatchNorm1d(hidden_dim)

        # single-task runtime head
        self.head_fc1 = nn.Linear(hidden_dim, head_dim)
        self.batch_norm3 = nn.BatchNorm1d(head_dim)
        self.head_fc2 = nn.Linear(head_dim, head_dim)
        self.out_fc = nn.Linear(head_dim, 1)

    def init_hidden(self, hidden_dim: int, batch_size: int, device: torch.device):
        return (
            torch.zeros(1, batch_size, hidden_dim, device=device),
            torch.zeros(1, batch_size, hidden_dim, device=device),
        )

    def forward(
        self,
        operators: torch.Tensor,
        extra_infos: torch.Tensor,
        condition1s: torch.Tensor,
        condition2s: torch.Tensor,
        samples: torch.Tensor,
        condition_masks: torch.Tensor,
        mapping: torch.Tensor,
    ) -> torch.Tensor:
        """
        Returns
        -------
        out : [batch_size, 1]
            Predicted normalized log-runtime in [0, 1]
        """
        device = operators.device

        # infer actual batch size from non-zero root operator rows, matching notebook logic
        batch_size = 0
        for i in range(operators.size(1)):
            if operators[0, i].sum() != 0:
                batch_size += 1
            else:
                break

        num_level = condition1s.size(0)
        num_node_per_level = condition1s.size(1)
        num_condition_per_node = condition1s.size(2)
        condition_op_length = condition1s.size(3)

        # ------------------------------------------------------------
        # condition1 branch
        # ------------------------------------------------------------
        inputs = condition1s.view(num_level * num_node_per_level, num_condition_per_node, condition_op_length)
        hidden = self.init_hidden(self.hidden_dim, num_level * num_node_per_level, device)
        _, (hid, _) = self.lstm1(inputs, hidden)
        last_output1 = hid[0].view(num_level * num_node_per_level, -1)

        # ------------------------------------------------------------
        # condition2 branch
        # ------------------------------------------------------------
        inputs = condition2s.view(num_level * num_node_per_level, num_condition_per_node, condition_op_length)
        hidden = self.init_hidden(self.hidden_dim, num_level * num_node_per_level, device)
        _, (hid, _) = self.lstm1(inputs, hidden)
        last_output2 = hid[0].view(num_level * num_node_per_level, -1)

        # project and combine condition branches
        last_output1 = F.relu(self.condition_mlp(last_output1))
        last_output2 = F.relu(self.condition_mlp(last_output2))
        last_output = 0.5 * (last_output1 + last_output2)
        last_output = self.batch_norm1(last_output).view(num_level, num_node_per_level, -1)

        # sample branch
        sample_output = F.relu(self.sample_mlp(samples))
        sample_output = sample_output * condition_masks

        # node-level combined input to representation LSTM
        out = torch.cat((operators, extra_infos, last_output, sample_output), dim=2)

        # ------------------------------------------------------------
        # bottom-up level-wise composition using mapping
        # ------------------------------------------------------------
        hidden = self.init_hidden(self.hidden_dim, num_node_per_level, device)
        last_level = out[num_level - 1].view(num_node_per_level, 1, -1)
        _, (hid, cid) = self.lstm2(last_level, hidden)

        mapping = mapping.long()

        for idx in reversed(range(0, num_level - 1)):
            mapp_left = mapping[idx][:, 0]
            mapp_right = mapping[idx][:, 1]

            # prepend zero-state so child index 0 means "missing child"
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

        output = hid[0]                 # [N, hidden_dim]
        output = output[0:batch_size]   # keep only actual roots in this merged batch
        output = self.batch_norm2(output)

        # runtime head
        h = F.relu(self.head_fc1(output))
        h = self.batch_norm3(h)
        h = F.relu(self.head_fc2(h))
        out = torch.sigmoid(self.out_fc(h))  # normalized log-runtime in [0,1]

        return out