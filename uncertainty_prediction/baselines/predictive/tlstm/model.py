from __future__ import annotations

from typing import Dict, Any, Optional
import torch
import torch.nn as nn
import torch.nn.functional as F


class TLSTMEncoder(nn.Module):
    """
    Trino-adapted TLSTM encoder.

    Expected input shapes
    ---------------------
    operators      : [L, N, operator_dim]
    extra_infos    : [L, N, extra_dim]
    condition1s    : [L, N, C, condition_op_dim]
    condition2s    : [L, N, C, condition_op_dim]
    samples        : [L, N, sample_dim]
    condition_masks: [L, N, 1] or [L, N]
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
        self.head_dim = head_dim

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

        # shared prediction trunk
        self.head_fc1 = nn.Linear(hidden_dim, head_dim)
        self.batch_norm3 = nn.BatchNorm1d(head_dim)
        self.head_fc2 = nn.Linear(head_dim, head_dim)

    def init_hidden(self, hidden_dim: int, batch_size: int, device: torch.device):
        return (
            torch.zeros(1, batch_size, hidden_dim, device=device),
            torch.zeros(1, batch_size, hidden_dim, device=device),
        )

    def _infer_actual_batch_size(self, operators: torch.Tensor) -> int:
        """
        Root rows are packed left-to-right in the merged batch.
        Stop at the first all-zero padded root row.
        """
        batch_size = 0
        for i in range(operators.size(1)):
            if operators[0, i].sum() != 0:
                batch_size += 1
            else:
                break
        return batch_size

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
        z : [batch_size, head_dim]
            Learned query embedding for downstream runtime prediction.
        """
        device = operators.device
        batch_size = self._infer_actual_batch_size(operators)

        num_level = condition1s.size(0)
        num_node_per_level = condition1s.size(1)
        num_condition_per_node = condition1s.size(2)
        condition_op_length = condition1s.size(3)

        # ------------------------------------------------------------
        # condition1 branch
        # ------------------------------------------------------------
        inputs = condition1s.reshape(
            num_level * num_node_per_level,
            num_condition_per_node,
            condition_op_length,
        )
        hidden = self.init_hidden(self.hidden_dim, num_level * num_node_per_level, device)
        _, (hid, _) = self.lstm1(inputs, hidden)
        last_output1 = hid[0].reshape(num_level * num_node_per_level, -1)

        # ------------------------------------------------------------
        # condition2 branch
        # ------------------------------------------------------------
        inputs = condition2s.reshape(
            num_level * num_node_per_level,
            num_condition_per_node,
            condition_op_length,
        )
        hidden = self.init_hidden(self.hidden_dim, num_level * num_node_per_level, device)
        _, (hid, _) = self.lstm1(inputs, hidden)
        last_output2 = hid[0].reshape(num_level * num_node_per_level, -1)

        # project and combine condition branches
        last_output1 = F.relu(self.condition_mlp(last_output1))
        last_output2 = F.relu(self.condition_mlp(last_output2))
        last_output = 0.5 * (last_output1 + last_output2)
        last_output = self.batch_norm1(last_output).reshape(num_level, num_node_per_level, -1)

        # sample branch
        sample_output = F.relu(self.sample_mlp(samples))
        if condition_masks.dim() == 2:
            condition_masks = condition_masks.unsqueeze(-1)
        sample_output = sample_output * condition_masks

        # node-level combined input to representation LSTM
        out = torch.cat((operators, extra_infos, last_output, sample_output), dim=2)

        # ------------------------------------------------------------
        # bottom-up level-wise composition using mapping
        # ------------------------------------------------------------
        hidden = self.init_hidden(self.hidden_dim, num_node_per_level, device)
        last_level = out[num_level - 1].reshape(num_node_per_level, 1, -1)
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

            current_level = out[idx].reshape(num_node_per_level, 1, -1)
            _, (hid, cid) = self.lstm2(current_level, (hid, cid))

        output = hid[0]               # [N, hidden_dim]
        output = output[0:batch_size] # keep only actual roots in this merged batch
        output = self.batch_norm2(output)

        h = F.relu(self.head_fc1(output))
        h = self.batch_norm3(h)
        z = F.relu(self.head_fc2(h))

        return z


class HeteroscedasticRuntimeHead(nn.Module):
    """
    Predicts:

      logT ~ Normal(mu_log(z), sigma_log(z)^2)

    where the model outputs mu_log and log_sigma.
    """

    def __init__(
        self,
        in_dim: int,
        *,
        hidden_dim: int = 64,
        log_sigma_min: float = -3.0,
        log_sigma_max: float = 3.0,
        eps_sigma: float = 1e-6,
    ):
        super().__init__()
        self.hidden_dim = hidden_dim
        self.log_sigma_min = log_sigma_min
        self.log_sigma_max = log_sigma_max
        self.eps_sigma = eps_sigma

        self.fc1 = nn.Linear(in_dim, hidden_dim)
        self.fc_mu = nn.Linear(hidden_dim, 1)
        self.fc_ls = nn.Linear(hidden_dim, 1)

        # sensible initialisation for variance head bias
        nn.init.constant_(self.fc_ls.bias, -0.5)

    def forward(self, z: torch.Tensor):
        h = F.relu(self.fc1(z))
        mu_log = self.fc_mu(h).squeeze(-1)
        log_sigma = self.fc_ls(h).squeeze(-1)
        log_sigma = torch.clamp(log_sigma, self.log_sigma_min, self.log_sigma_max)
        return mu_log, log_sigma


class TLSTMHeteroRuntimeRegressor(nn.Module):
    """
    Full end-to-end probabilistic TLSTM:

      plan -> TLSTMEncoder -> z -> heteroscedastic head -> (mu_log, log_sigma)
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
        hetero_hidden_dim: int = 64,
        log_sigma_min: float = -3.0,
        log_sigma_max: float = 3.0,
        eps_sigma: float = 1e-6,
    ):
        super().__init__()

        self.encoder = TLSTMEncoder(
            operator_dim=operator_dim,
            extra_dim=extra_dim,
            condition_op_dim=condition_op_dim,
            sample_dim=sample_dim,
            hidden_dim=hidden_dim,
            hid_dim=hid_dim,
            head_dim=head_dim,
        )

        self.runtime_head = HeteroscedasticRuntimeHead(
            in_dim=head_dim,
            hidden_dim=hetero_hidden_dim,
            log_sigma_min=log_sigma_min,
            log_sigma_max=log_sigma_max,
            eps_sigma=eps_sigma,
        )

        self.log_sigma_min = log_sigma_min
        self.log_sigma_max = log_sigma_max
        self.eps_sigma = eps_sigma

    def forward(
        self,
        operators: torch.Tensor,
        extra_infos: torch.Tensor,
        condition1s: torch.Tensor,
        condition2s: torch.Tensor,
        samples: torch.Tensor,
        condition_masks: torch.Tensor,
        mapping: torch.Tensor,
    ):
        z = self.encoder(
            operators=operators,
            extra_infos=extra_infos,
            condition1s=condition1s,
            condition2s=condition2s,
            samples=samples,
            condition_masks=condition_masks,
            mapping=mapping,
        )
        mu_log, log_sigma = self.runtime_head(z)
        return mu_log, log_sigma, z

    @torch.no_grad()
    def predict_distribution(
        self,
        operators: torch.Tensor,
        extra_infos: torch.Tensor,
        condition1s: torch.Tensor,
        condition2s: torch.Tensor,
        samples: torch.Tensor,
        condition_masks: torch.Tensor,
        mapping: torch.Tensor,
    ) -> Dict[str, torch.Tensor]:
        self.eval()
        mu_log, log_sigma, z = self.forward(
            operators=operators,
            extra_infos=extra_infos,
            condition1s=condition1s,
            condition2s=condition2s,
            samples=samples,
            condition_masks=condition_masks,
            mapping=mapping,
        )
        sigma_log = torch.exp(log_sigma).clamp_min(self.eps_sigma)
        mean_runtime = torch.exp(mu_log)
        return {
            "mu_log": mu_log,
            "log_sigma": log_sigma,
            "sigma_log": sigma_log,
            "mean_runtime_proxy": mean_runtime,
            "embedding": z,
        }

    @torch.no_grad()
    def sample_log_runtime(
        self,
        operators: torch.Tensor,
        extra_infos: torch.Tensor,
        condition1s: torch.Tensor,
        condition2s: torch.Tensor,
        samples: torch.Tensor,
        condition_masks: torch.Tensor,
        mapping: torch.Tensor,
        *,
        num_samples: int = 100,
    ) -> torch.Tensor:
        self.eval()
        mu_log, log_sigma, _ = self.forward(
            operators=operators,
            extra_infos=extra_infos,
            condition1s=condition1s,
            condition2s=condition2s,
            samples=samples,
            condition_masks=condition_masks,
            mapping=mapping,
        )
        sigma_log = torch.exp(log_sigma).clamp_min(self.eps_sigma)
        dist = torch.distributions.Normal(
            loc=mu_log.unsqueeze(0),
            scale=sigma_log.unsqueeze(0),
        )
        return dist.sample((num_samples,)).squeeze(1)

    @torch.no_grad()
    def sample_runtime(
        self,
        operators: torch.Tensor,
        extra_infos: torch.Tensor,
        condition1s: torch.Tensor,
        condition2s: torch.Tensor,
        samples: torch.Tensor,
        condition_masks: torch.Tensor,
        mapping: torch.Tensor,
        *,
        num_samples: int = 100,
    ) -> torch.Tensor:
        return torch.exp(
            self.sample_log_runtime(
                operators=operators,
                extra_infos=extra_infos,
                condition1s=condition1s,
                condition2s=condition2s,
                samples=samples,
                condition_masks=condition_masks,
                mapping=mapping,
                num_samples=num_samples,
            )
        )


def gaussian_nll_from_log_sigma(
    mu_log: torch.Tensor,
    log_sigma: torch.Tensor,
    target_log_runtime: torch.Tensor,
    *,
    reduction: str = "mean",
) -> torch.Tensor:
    """
    Gaussian negative log likelihood for:

      y ~ Normal(mu_log, sigma^2)
      sigma = exp(log_sigma)

    Up to the usual additive constant 0.5 * log(2*pi).
    """
    target_log_runtime = target_log_runtime.reshape(-1)
    mu_log = mu_log.reshape(-1)
    log_sigma = log_sigma.reshape(-1)

    var = torch.exp(2.0 * log_sigma).clamp_min(1e-12)
    loss = 0.5 * ((target_log_runtime - mu_log) ** 2 / var + torch.log(var))

    if reduction == "none":
        return loss
    if reduction == "sum":
        return loss.sum()
    if reduction == "mean":
        return loss.mean()
    raise ValueError(f"Unknown reduction: {reduction}")


@torch.no_grad()
def prediction_interval_from_log_normal(
    mu_log: torch.Tensor,
    sigma_log: torch.Tensor,
    *,
    z_value: float = 1.96,
):
    """
    Converts a Normal distribution in log-space into an interval in runtime space.
    """
    lower = torch.exp(mu_log - z_value * sigma_log)
    median = torch.exp(mu_log)
    upper = torch.exp(mu_log + z_value * sigma_log)
    return lower, median, upper