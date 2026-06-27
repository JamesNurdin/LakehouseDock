from dataclasses import dataclass
from typing import Optional, Protocol, Dict, FrozenSet, Tuple, List
import math
import numpy as np


# ============================================================
# Penalty interface (abstract "base" via Protocol)
# ============================================================

@dataclass(frozen=True)
class PenaltyKey:
    name: str
    weight: float

class Penalty(Protocol):
    """
    A penalty adds a non-negative (usually) start-dependent cost coefficient
    to the objective for choosing start time 'start_abs' for query 'q'.

    The scheduler will do:
        obj += (carbon_cost + sum(p.coeff(...))) * x[qid,k]

    Notes:
    - bind(cp) lets you cache CP-derived constants (e.g., ci_ref).
    - coeff(...) must return a plain float (no Gurobi expressions).
    """

    name: str
    weight: int

    @property
    def key(self) -> PenaltyKey:
        return PenaltyKey(self.name, self.weight)

    def bind(self, cp) -> "Penalty":
        ...

    def coeff(
        self,
        *,
        q,              # QuerySpec
        start_abs: int, # absolute start slot
        dur_slots: int, # planning duration used in MILP (e.g., mu or inflated)
        cp,             # CarbonProfile
    ) -> float:
        ...

    def filter(
        self,
        *,
        q,                    # QuerySpec
        valid_ks: List[int],  # raw candidate start indices for this query
        start_abs: List[int],
        dur_slots: int,
        cp,                   # CarbonProfile
    ) -> Optional[List[int]]:
        ...

    def merge(
        self,
        *,
        q,                         # QuerySpec
        base_ks: List[int],        # candidates from base low-carbon filter
        policy_ks: List[int],      # candidates returned by this penalty's filter
        raw_ks: List[int],         # raw candidate start indices
    ) -> Optional[List[int]]:
        ...


# ============================================================
# Helpers
# ============================================================

def _clamp_slot(cp, idx: int) -> int:
    return int(min(max(0, int(idx)), int(cp.num_slots) - 1))

def mean_ci_over_window_abs(cp, start_abs: int, dur_slots: int) -> float:
    s = _clamp_slot(cp, start_abs)
    e = _clamp_slot(cp, start_abs + int(max(1, dur_slots)))
    e = max(e, s + 1)
    if hasattr(cp, "ci_prefix") and cp.ci_prefix is not None:
        return float((cp.ci_prefix[e] - cp.ci_prefix[s]) / float(e - s))
    return float(np.mean(cp.ci[s:e]))

def ci_at_abs(cp, start_abs: int) -> float:
    return float(cp.ci[_clamp_slot(cp, start_abs)])

def ci_sum_over_window_abs(cp, start_abs: int, dur_slots: int) -> float:
    """
    Sum CI over [start_abs, start_abs + dur_slots) using prefix sums if present.
    """
    s = _clamp_slot(cp, start_abs)
    e = _clamp_slot(cp, start_abs + int(max(1, dur_slots)))
    e = max(e, s + 1)
    if hasattr(cp, "ci_prefix") and cp.ci_prefix is not None:
        return float(cp.ci_prefix[e] - cp.ci_prefix[s])
    return float(np.sum(cp.ci[s:e]))


# ============================================================
# Penalties
# ============================================================

@dataclass(frozen=True)
class WindowCIRiskPenalty:
    """
    penalty = lam * sigma_dur * (mean_CI(window) / CI_ref )^power
    """
    name: str = "window_ci_risk"
    weight: int = 100
    
    lam: float = 1.0
    power: float = 1.0
    ci_ref: Optional[float] = None

    @property
    def key(self) -> PenaltyKey:
        return PenaltyKey(self.name, self.weight)

    def bind(self, cp):
        if self.ci_ref is None:
            return WindowCIRiskPenalty(
                lam=self.lam,
                power=self.power,
                ci_ref=float(np.mean(cp.ci)),
                name=self.name,
            )
        return self

    def coeff(self, *, q, start_abs: int, dur_slots: int,  cp) -> float:
        sigma = float(getattr(q, "dur_std_slots_pred", 0.0))
        if sigma <= 0.0:
            return 0.0
        ci_ref = float(self.ci_ref) if self.ci_ref is not None else float(np.mean(cp.ci))
        ci_bar = mean_ci_over_window_abs(cp, int(start_abs), int(dur_slots))
        ratio = (ci_bar / max(1e-9, ci_ref)) ** float(self.power)
        return float(self.lam) * sigma * ratio


@dataclass(frozen=True)
class ObjectiveRiskPenalty:
    """
    penalty = lam * sigma * w(CI)

    w(CI) = 1                           if ci_weighted=False
          = (CI(start)/CI_ref)^power    if ci_weighted=True
    """
    name: str = "objective_risk"
    weight: int = 100
    
    lam: float = 1.0
    ci_weighted: bool = True
    power: float = 1.0
    ci_ref: Optional[float] = None

    def bind(self, cp):
        if self.ci_weighted and self.ci_ref is None:
            return ObjectiveRiskPenalty(
                lam=self.lam,
                ci_weighted=self.ci_weighted,
                power=self.power,
                ci_ref=float(np.mean(cp.ci)),
                name=self.name,
            )
        return self

    def coeff(self, *, q, start_abs: int, dur_slots: int,  cp) -> float:
        sigma = float(q.dur_std_slots_pred)
        if sigma <= 0.0:
            return 0.0

        base = float(self.lam) * sigma
        if not self.ci_weighted:
            return float(base)

        ci_ref = float(self.ci_ref) if self.ci_ref is not None else float(np.mean(cp.ci))
        ratio = (ci_at_abs(cp, start_abs) / max(1e-9, ci_ref)) ** float(self.power)
        return float(base * ratio)


@dataclass(frozen=True)
class OverrunProbabilityPenalty:
    """
    penalty = lam * p_over * (mean_CI(window)/CI_ref)^power   if ci_weighted
            = lam * p_over                                    otherwise
            
    p_over = P(T > mu + z_margin*sigma) under Normal approx -> 1 - Phi(z_margin)
    """
    name: str = "overrun_probability_penalty"
    weight: int = 100
    
    lam: float = 1.0
    z_margin: float = 0.0
    ci_weighted: bool = True
    power: float = 1.0
    ci_ref: Optional[float] = None

    _ONE_MINUS_PHI = {
        0.0: 0.5,
        0.5: 0.3085375387259869,
        1.0: 0.15865525393145707,
        1.2815515655446004: 0.10,
        1.6448536269514722: 0.05,
        2.3263478740408408: 0.01,
    }

    def bind(self, cp):
        if self.ci_weighted and self.ci_ref is None:
            return OverrunProbabilityPenalty(
                lam=self.lam,
                z_margin=self.z_margin,
                ci_weighted=self.ci_weighted,
                power=self.power,
                ci_ref=float(np.mean(cp.ci)),
                name=self.name,
            )
        return self

    def coeff(self, *, q, start_abs: int, dur_slots: int,  cp) -> float:
        sigma = float(q.dur_std_slots_pred)
        if sigma <= 0.0:
            return 0.0

        z = float(self.z_margin)
        if z in self._ONE_MINUS_PHI:
            p_over = float(self._ONE_MINUS_PHI[z])
        else:
            Phi = 0.5 * (1.0 + math.erf(z / math.sqrt(2.0)))
            p_over = float(max(0.0, min(1.0, 1.0 - Phi)))

        pen = float(self.lam) * p_over
        if not self.ci_weighted:
            return float(pen)

        ci_ref = float(self.ci_ref) if self.ci_ref is not None else float(np.mean(cp.ci))
        ci_bar = mean_ci_over_window_abs(cp, int(start_abs), int(dur_slots))
        ratio = (ci_bar / max(1e-9, ci_ref)) ** float(self.power)

        return float(pen * ratio)



@dataclass(frozen=True)
class ResourceStdPenalty:
    """
    Penalise uncertainty in CPU/RAM predictions irrespective of CI.
      penalty = lam_cpu * cpu_std + lam_ram * ram_std
    This discourages "high-uncertainty" jobs unless carbon is very favourable.
    """
    name: str = "resource_std"
    weight: int = 100
    
    lam_cpu: float = 0.0
    lam_ram: float = 0.0

    def bind(self, cp):
        return self

    def coeff(self, *, q, start_abs: int, dur_slots: int,  cp) -> float:
        cpu_s = float(getattr(q, "cpu_std_pred", 0.0))
        ram_s = float(getattr(q, "ram_std_pred", 0.0))
        return float(self.lam_cpu) * cpu_s + float(self.lam_ram) * ram_s


@dataclass(frozen=True)
class LatenessPenalty:
    """
    Exponentially penalise lateness based on priority.

    Priority convention:
      0 = highest priority
      prio_hi = lowest priority
    """
    prio_hi: int
    name: str = "lateness_prio_exp"
    weight: float = 100.0
    beta: float = 2.0
    power: float = 1.0

    # filtering behaviour
    r_min: float = 0.20   # lowest-priority shortlist fraction
    r_max: float = 1.00   # highest-priority shortlist fraction
    keep_last: bool = False

    def bind(self, cp):
        return self

    def coeff(self, *, q, start_abs: int, dur_slots: int, cp) -> float:
        submission = float(getattr(q, "submission_time", 0.0))
        wait = float(max(0.0, float(start_abs) - submission))

        p = float(getattr(q, "priority", 0.0))
        hi = float(self.prio_hi)

        if hi <= 0:
            alpha = 0.0
        else:
            alpha = min(1.0, max(0.0, p / hi))

        # p=0 highest priority => largest multiplier
        prio_mult = math.exp(self.beta * (1.0 - alpha))
        return prio_mult * (wait ** self.power)

    @property
    def key(self) -> PenaltyKey:
        return PenaltyKey(self.name, self.weight)

    def _priority_alpha(self, q) -> float:
        """
        Return alpha in [0,1], where:
          0 = lowest priority
          1 = highest priority
        """
        p = float(getattr(q, "priority", 0.0))
        hi = float(self.prio_hi)
        if hi <= 0:
            return 1.0
        return float(1.0 - min(1.0, max(0.0, p / hi)))

    def _retention_ratio(self, q) -> float:
        """
        Highest priority -> r_max
        Lowest priority  -> r_min
        """
        if not (0.0 < self.r_min <= self.r_max <= 1.0):
            raise ValueError("Require 0 < r_min <= r_max <= 1.")

        alpha = self._priority_alpha(q)
        return float(self.r_min + alpha * (self.r_max - self.r_min))

    def filter(
        self,
        *,
        q,
        valid_ks: List[int],
        start_abs: List[int],
        dur_slots: int,
        cp,
    ) -> Optional[List[int]]:
        if not valid_ks:
            return []

        ratio = self._retention_ratio(q)
        keep_n = max(1, min(len(valid_ks), int(math.ceil(ratio * len(valid_ks)))))

        # earliest starts are best for lateness
        kept = set(valid_ks[:keep_n])

        if self.keep_last:
            kept.add(valid_ks[-1])

        return sorted(kept)

    def merge(
        self,
        *,
        q,
        base_ks: List[int],
        policy_ks: List[int],
        raw_ks: List[int],
    ) -> Optional[List[int]]:
        return sorted(set(base_ks) | set(policy_ks))


@dataclass(frozen=True)
class CarbonVarianceProxyPenalty:
    """
    A 'mean + risk' style carbon penalty proxy:
      penalty ≈ lam * (dur_std_slots_pred) * power_kw * dt_hours * mean_CI(window)

    This makes the objective favour starts where the CI level is low when runtime is uncertain.
    """
    name: str = "carbon_risk_proxy"
    weight: int = 100
    
    lam: float = 1.0

    def bind(self, cp):
        return self

    def coeff(self, *, q, start_abs: int, dur_slots: int,  cp) -> float:
        sigma = float(getattr(q, "dur_std_slots_pred", 0.0))
        if sigma <= 0.0:
            return 0.0
        power_kw = float(getattr(q, "power_kw", 0.0))
        dt_hours = float(getattr(cp, "dt_hours", 0.0))
        ci_bar = mean_ci_over_window_abs(cp, int(start_abs), int(dur_slots))
        return float(self.lam) * sigma * power_kw * dt_hours * ci_bar


@dataclass(frozen=True)
class BudgetedUncertaintyPenalty:
    """
    Port of "budgeted robustness" but as an objective-only penalty (no duration inflation).

    Usage:
      mu_by = {q.qid: q.dur_mean_slots_pred for q in specs}
      sg_by = {q.qid: q.dur_std_slots_pred for q in specs}
      pen = BudgetedUncertaintyPenalty(gamma_ratio=0.10, lam=0.5, score="cv").fit(mu_by, sg_by).bind(cp)

    penalty applies ONLY to qids in robust_set:
      penalty = lam * score(q) * (mean_CI(window)/CI_ref)^power   if ci_weighted
              = lam * score(q)                                   otherwise
    """
    name: str = "budgeted_uncertainty_penalty"
    weight: int = 100
    
    Gamma: int = 5
    gamma_ratio: Optional[float] = None
    lam: float = 1.0
    score: str = "sigma"          # "sigma" or "cv"

    ci_weighted: bool = True
    power: float = 1.0
    ci_ref: Optional[float] = None

    robust_set: FrozenSet[str] = frozenset()

    def _resolve_G(self, N: int) -> int:
        if self.gamma_ratio is None:
            return int(max(0, self.Gamma))
        r = float(self.gamma_ratio)
        if not (0.0 <= r <= 1.0):
            raise ValueError("gamma_ratio must be in [0, 1]")
        return int(max(0, math.ceil(r * int(N))))

    def fit(self, mu_by_id: Dict[str, float], sigma_by_id: Dict[str, float]) -> "BudgetedUncertaintyPenalty":
        N = len(mu_by_id)
        G = self._resolve_G(N)
        if G == 0:
            return BudgetedUncertaintyPenalty(
                Gamma=self.Gamma,
                gamma_ratio=self.gamma_ratio,
                lam=self.lam,
                score=self.score,
                ci_weighted=self.ci_weighted,
                power=self.power,
                ci_ref=self.ci_ref,
                robust_set=frozenset(),
                name=self.name,
            )

        scores: List[Tuple[str, float]] = []
        for jid, mu in mu_by_id.items():
            sg = float(sigma_by_id.get(jid, 0.0))
            if self.score == "cv":
                sc = sg / max(1e-9, float(mu))
            elif self.score == "sigma":
                sc = sg
            else:
                raise ValueError("score must be 'sigma' or 'cv'")
            scores.append((str(jid), float(sc)))

        scores.sort(key=lambda x: x[1], reverse=True)
        chosen = [jid for jid, _ in scores[:G]]

        return BudgetedUncertaintyPenalty(
            Gamma=self.Gamma,
            gamma_ratio=self.gamma_ratio,
            lam=self.lam,
            score=self.score,
            ci_weighted=self.ci_weighted,
            power=self.power,
            ci_ref=self.ci_ref,
            robust_set=frozenset(chosen),
            name=self.name,
        )

    def bind(self, cp):
        if self.ci_weighted and self.ci_ref is None:
            return BudgetedUncertaintyPenalty(
                Gamma=self.Gamma,
                gamma_ratio=self.gamma_ratio,
                lam=self.lam,
                score=self.score,
                ci_weighted=self.ci_weighted,
                power=self.power,
                ci_ref=float(np.mean(cp.ci)),
                robust_set=self.robust_set,
                name=self.name,
            )
        return self

    def coeff(self, *, q, start_abs: int, dur_slots: int,  cp) -> float:
        if q.qid not in self.robust_set:
            return 0.0

        sigma = float(q.dur_std_slots_pred)
        mu = float(q.dur_mean_slots_pred)

        risk = (sigma / max(1e-9, mu)) if (self.score == "cv") else sigma
        pen = float(self.lam) * float(risk)

        if not self.ci_weighted:
            return float(pen)

        ci_ref = float(self.ci_ref) if self.ci_ref is not None else float(np.mean(cp.ci))
        ci_bar = mean_ci_over_window_abs(cp, int(start_abs), int(dur_slots))
        ratio = (ci_bar / max(1e-9, ci_ref)) ** float(self.power)
        return float(pen * ratio)
