from __future__ import annotations

import torch
import torch.nn as nn
import torch.nn.functional as F


class TNNRuntimeRegressor(nn.Module):
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

        self.lstm1 = nn.LSTM(condition_op_dim, hidden_dim, batch_first=True)
        self.condition_mlp = nn.Linear(hidden_dim, hid_dim)
        self.batch_norm1 = nn.BatchNorm1d(hid_dim)

        self.sample_mlp = nn.Linear(sample_dim, hid_dim)

        self.node_input_dim = operator_dim + extra_dim + 2 * hid_dim

        self.rep_fc1 = nn.Linear(self.node_input_dim + 2 * hidden_dim, hidden_dim)
        self.rep_fc2 = nn.Linear(hidden_dim, hidden_dim)
        self.batch_norm2 = nn.BatchNorm1d(hidden_dim)

        self.head_fc1 = nn.Linear(hidden_dim, head_dim)
        self.batch_norm3 = nn.BatchNorm1d(head_dim)
        self.head_fc2 = nn.Linear(head_dim, head_dim)
        self.out_fc = nn.Linear(head_dim, 1)

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
        device = operators.device

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

        # condition1 branch
        inputs = condition1s.view(num_level * num_node_per_level, num_condition_per_node, condition_op_length)
        h0 = torch.zeros(1, num_level * num_node_per_level, self.hidden_dim, device=device)
        c0 = torch.zeros(1, num_level * num_node_per_level, self.hidden_dim, device=device)
        _, (hid, _) = self.lstm1(inputs, (h0, c0))
        last_output1 = hid[0].view(num_level * num_node_per_level, -1)

        # condition2 branch
        inputs = condition2s.view(num_level * num_node_per_level, num_condition_per_node, condition_op_length)
        h0 = torch.zeros(1, num_level * num_node_per_level, self.hidden_dim, device=device)
        c0 = torch.zeros(1, num_level * num_node_per_level, self.hidden_dim, device=device)
        _, (hid, _) = self.lstm1(inputs, (h0, c0))
        last_output2 = hid[0].view(num_level * num_node_per_level, -1)

        last_output1 = F.relu(self.condition_mlp(last_output1))
        last_output2 = F.relu(self.condition_mlp(last_output2))
        cond_output = 0.5 * (last_output1 + last_output2)
        cond_output = self.batch_norm1(cond_output).view(num_level, num_node_per_level, -1)

        sample_output = F.relu(self.sample_mlp(samples))
        sample_output = sample_output * condition_masks

        node_out = torch.cat((operators, extra_infos, cond_output, sample_output), dim=2)

        mapping = mapping.long()

        # deepest level: no child reps
        zero_rep = torch.zeros(num_node_per_level, self.hidden_dim, device=device)
        current_level = node_out[num_level - 1]
        rep_input = torch.cat([zero_rep, zero_rep, current_level], dim=1)
        rep = F.relu(self.rep_fc1(rep_input))
        rep = F.relu(self.rep_fc2(rep))

        for idx in reversed(range(0, num_level - 1)):
            mapp_left = mapping[idx][:, 0]
            mapp_right = mapping[idx][:, 1]

            zero_row = torch.zeros(1, self.hidden_dim, device=device)
            next_rep = torch.cat((zero_row, rep), dim=0)

            rep_left = torch.index_select(next_rep, 0, mapp_left)
            rep_right = torch.index_select(next_rep, 0, mapp_right)

            current_level = node_out[idx]
            rep_input = torch.cat([rep_left, rep_right, current_level], dim=1)
            rep = F.relu(self.rep_fc1(rep_input))
            rep = F.relu(self.rep_fc2(rep))

        output = rep[0:batch_size]
        output = self.batch_norm2(output)

        h = F.relu(self.head_fc1(output))
        h = self.batch_norm3(h)
        h = F.relu(self.head_fc2(h))
        out = torch.sigmoid(self.out_fc(h))
        return out