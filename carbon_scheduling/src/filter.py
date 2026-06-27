from dataclasses import dataclass
from typing import Dict, List, Optional, Protocol
import math
import numpy as np


from carbon_scheduling.src.structs import QuerySpec
from carbon_scheduling.src.carbon import CarbonProfile
from carbon_scheduling.src.objective import ObjectiveFunction
from carbon_scheduling.src.penalty import Penalty


@dataclass
class FilterRunStats:
    raw_total: int = 0
    final_total: int = 0
    removed_abs: int = 0
    removed_pct: float = 0.0


@dataclass
class QueryFilterContext:
    valid_ks: Dict[str, List[int]]
    start_abs: List[int]
    pending_by_qid: Dict[str, QuerySpec]
    dur: Dict[str, int]
    cpu: Dict[str, float]
    ram: Dict[str, float]
    pkw_by_qid: Dict[str, float]
    cp: CarbonProfile
    penalties_bound: List[Penalty]
    objective: ObjectiveFunction
    now_slot: int = 0
    raw_valid_ks: Optional[Dict[str, List[int]]] = None


class LowCarbonFilter:
    """
    Keep candidate starts that fall in globally low-CI periods.

    The strictness is controlled by the CoV of the global CI signal:
      - low CoV  -> looser threshold
      - high CoV -> stricter threshold

    Uses a bounded, saturating CoV -> quantile mapping so that:
      - weak CI signals do not over-prune
      - strong CI signals do not become arbitrarily aggressive
      - behaviour is more stable across countries and horizon lengths

    This is intended only to remove clearly illogical high-CI choices
    from the MILP, not to approximate the full optimum.
    """

    def __init__(
        self,
        *,
        q_lo: float = 0.50,   # weak signal -> broader acceptable low-CI region
        q_hi: float = 0.20,   # strong signal -> narrower acceptable low-CI region
        cov_lo: float = 0.05, # below this, treat signal as weak
        cov_hi: float = 0.30, # above this, treat signal as strong/saturated
        keep_first: bool = False,
    ):
        if not (0.0 < q_hi <= q_lo < 1.0):
            raise ValueError("Require 0 < q_hi <= q_lo < 1.")
        if not (0.0 <= cov_lo < cov_hi):
            raise ValueError("Require 0 <= cov_lo < cov_hi.")

        self.q_lo = float(q_lo)
        self.q_hi = float(q_hi)
        self.cov_lo = float(cov_lo)
        self.cov_hi = float(cov_hi)
        self.keep_first = bool(keep_first)

    def _quantile_from_cov(self, cov: float) -> float:
        """
        Map CoV to a retention quantile using a bounded smoothstep transform.

        - cov <= cov_lo  -> q_lo
        - cov >= cov_hi  -> q_hi
        - in between     -> smooth interpolation

        This avoids overreacting to large CoV values once the signal is already
        clearly informative.
        """
        cov = max(0.0, float(cov))

        if cov <= self.cov_lo:
            return self.q_lo
        if cov >= self.cov_hi:
            return self.q_hi

        # Normalize to [0, 1]
        x = (cov - self.cov_lo) / (self.cov_hi - self.cov_lo)

        # Smoothstep: 3x^2 - 2x^3
        # Gives smoother, less twitchy behaviour than a plain linear map.
        x = x * x * (3.0 - 2.0 * x)

        # low CoV -> q near q_lo
        # high CoV -> q near q_hi
        return float(self.q_lo - (self.q_lo - self.q_hi) * x)

    def filter(self, ctx: QueryFilterContext) -> Dict[str, List[int]]:
        base = ctx.raw_valid_ks if ctx.raw_valid_ks is not None else ctx.valid_ks
        ci = np.asarray(ctx.cp.ci, dtype=float)
        ci_prefix = ctx.cp.ci_prefix

        out: Dict[str, List[int]] = {}

        # Global signal strength from CarbonProfile
        cov = float(ctx.cp.ci_cov())

        # Map CoV to a global CI quantile threshold
        q = self._quantile_from_cov(cov)
        global_ci_threshold = float(np.quantile(ci, q))

        for qid, ks in base.items():
            if not ks:
                out[qid] = []
                continue

            d = int(ctx.dur[qid])
            kept = set()

            for k in ks:
                s = int(ctx.start_abs[k])

                # Average CI across the query's execution window
                ci_avg = float(ci_prefix[s + d] - ci_prefix[s]) / float(d)

                if ci_avg <= global_ci_threshold:
                    kept.add(k)

            # Optional anchor
            if self.keep_first and ks:
                kept.add(ks[0])

            out[qid] = sorted(kept)

        return out

class QueryFilterPipeline:
    """
    Filtering pipeline with:
      1. mandatory base low-carbon filtering
      2. optional policy-aware candidate recovery from active penalties

    Records only before/after filtering totals.
    """

    def __init__(
        self,
        low_carbon_filter: "LowCarbonFilter",
        *,
        verbose: bool = False,
    ):
        self.low_carbon_filter = low_carbon_filter
        self.verbose = bool(verbose)
        self.last_stats: Optional[FilterRunStats] = None

    def _count_total(self, valid_ks: Dict[str, List[int] | set[int]]) -> int:
        return int(sum(len(ks) for ks in valid_ks.values()))

    def _pct_removed(self, kept: int, raw: int) -> float:
        if raw <= 0:
            return 0.0
        return 100.0 * (1.0 - (kept / raw))

    def _default_merge(
        self,
        *,
        base_ks: List[int],
        policy_ks: List[int],
    ) -> List[int]:
        return sorted(set(base_ks) | set(policy_ks))

    def filter(self, ctx: QueryFilterContext) -> Dict[str, List[int]]:
        raw_valid_ks = ctx.valid_ks
        ctx.raw_valid_ks = raw_valid_ks

        raw_total = self._count_total(raw_valid_ks)

        if self.verbose:
            print(f"[QueryFilterPipeline] raw candidates: {raw_total}")

        # Step 1: mandatory low-carbon filtering
        ctx.valid_ks = raw_valid_ks
        final_valid_ks = self.low_carbon_filter.filter(ctx)

        # Step 2: optional policy-aware recovery
        for penalty in ctx.penalties_bound:
            penalty_filter = getattr(penalty, "filter", None)
            if penalty_filter is None:
                continue

            for qid, raw_ks in raw_valid_ks.items():
                q = ctx.pending_by_qid[qid]
                d = int(ctx.dur[qid])

                policy_ks = penalty_filter(
                    q=q,
                    valid_ks=raw_ks,
                    start_abs=ctx.start_abs,
                    dur_slots=d,
                    cp=ctx.cp,
                )

                if not policy_ks:
                    continue

                current_ks = final_valid_ks.get(qid, [])
                merge_fn = getattr(penalty, "merge", None)

                if merge_fn is not None:
                    merged_ks = merge_fn(
                        q=q,
                        base_ks=current_ks,
                        policy_ks=policy_ks,
                        raw_ks=raw_ks,
                    )
                    if merged_ks is None:
                        merged_ks = self._default_merge(base_ks=current_ks, policy_ks=policy_ks)
                else:
                    merged_ks = self._default_merge(base_ks=current_ks, policy_ks=policy_ks)

                final_valid_ks[qid] = merged_ks

        final_total = self._count_total(final_valid_ks)
        removed_abs = raw_total - final_total
        removed_pct = self._pct_removed(final_total, raw_total)

        self.last_stats = FilterRunStats(
            raw_total=raw_total,
            final_total=final_total,
            removed_abs=removed_abs,
            removed_pct=removed_pct,
        )

        if self.verbose:
            print(
                f"[QueryFilterPipeline] final candidates: {final_total} "
                f"(removed {removed_abs} / {raw_total}, {removed_pct:.2f}% vs raw)"
            )

        return final_valid_ks