from dataclasses import dataclass, field
from typing import Dict, List, Callable

from carbon_scheduling.src.penalty import Penalty, PenaltyKey

@dataclass
class ObjectiveFunction:
    w_carbon: float = 1.0
    carbon_scale: float = 1.0

    penalty_scales: Dict[PenaltyKey, float] = field(default_factory=dict)
    penalty_key_fn: Callable[[Penalty], PenaltyKey] = lambda p: p.key

    default_penalty_scale: float = 1.0
    eps: float = 1e-9

    def cost(
        self,
        *,
        base_carbon: float,
        penalties_bound: List[Penalty],
        cached_penalty_vals: Dict[PenaltyKey, float],
    ) -> float:
        cs = max(self.eps, float(self.carbon_scale or 1.0))
        carbon_term = float(base_carbon) / cs

        pen_term = 0.0
        for p in penalties_bound:
            key = self.penalty_key_fn(p)
            s_i = max(self.eps, float(self.penalty_scales.get(key, self.default_penalty_scale)))
            p_i = float(cached_penalty_vals.get(key, 0.0))
            pen_term += float(p.weight) * (p_i / s_i)

        return float(self.w_carbon * carbon_term + pen_term)