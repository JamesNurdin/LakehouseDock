from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Tuple

import time
import pandas as pd

from carbon_scheduling.src.carbon import CarbonProfile, _carbon_for_interval, _planned_total_carbon, _realised_total_carbon
from carbon_scheduling.src.structs import QuerySpec, Plan, RunningJob, Logger, SchedulerResult
from carbon_scheduling.src.optimise import OptimiserProtocol, OptimiserMILP


class UncertaintyScheduler:

    def __init__(
        self,
        *,
        name: str,
        label: str,
        optimiser: OptimiserProtocol,
        cp: CarbonProfile,
        specs: List[QuerySpec],
        oracle_planning: bool = False,
        use_true_for_execution: bool = True,
        reopt_threshold: float | None = 0.25,
        logger: Logger = Logger(False),
        extra: Optional[Dict[str, Any]] = None,
    ):
        self.name = str(name)
        self.label = str(label)
        self.optimiser = optimiser
        self.cp = cp
        self.specs = list(specs)

        self.oracle_planning = bool(oracle_planning)                # Use predicted or actual values in determining the scheduler
        self.use_true_for_execution = bool(use_true_for_execution)  # Use predicted or actual values in the DES
        self.reopt_threshold = reopt_threshold                      # Determine when the schedule shoud be reoptimised
        self.logger = logger                          
        self.extra = dict(extra or {})
        

    def run(self) -> SchedulerResult:
        optimiser = self.optimiser
        cp = self.cp
        specs = self.specs
    
        # Fresh run state (important if you reuse sched object across runs)
        optimiser.running.clear()
        optimiser.completed.clear()
        if hasattr(optimiser, "started"):
            optimiser.started.clear()
    
        if getattr(optimiser, "_state", None) is not None:
            raise RuntimeError(
                "optimiser already has a built model (_state is not None). "
                "For batch runs, create a new optimiser per run OR implement optimiser.reset()."
            )
    
        # Build model once
        optimiser.build_model(cp=cp, specs=specs, use_true_for_planning=self.oracle_planning)
    
        pending: Dict[str, QuerySpec] = {q.qid: q for q in specs}
        realised: Dict[str, Tuple[int, int, float, float]] = {}  # qid -> (s,e,cpu,ram)
    
        now = 0
    
        num_reopts = 0
        num_idle_jumps = 0
        total_idle_slots = 0
    
        # initial schedule
        plan = optimiser.reoptimize(now_slot=now)
        num_reopts += 1
        self.logger.log(f"[t={now}] pending={len(pending)} running={len(optimiser.running)}")
    
        planned_start_slot: Dict[str, int] = dict(plan.start_slot)
    
        while pending or optimiser.running:
            # start jobs
            started: List[RunningJob] = optimiser.start_jobs_from_plan(
                now_slot=now,
                plan=plan,
                pending=pending,
                use_true_for_execution=self.use_true_for_execution,
            )
    
            for rj in started:
                pending.pop(rj.qid, None)
                realised[rj.qid] = (rj.start_slot, rj.actual_end_slot, rj.actual_cpu, rj.actual_ram)
    
            if started:
                self.logger.log(
                    f"[t={now}] START n={len(started)}"
                    f"pending={len(pending)} running={len(optimiser.running)}"
                )
    
            # advance time
            prev_now = now
            if not optimiser.running:
                future = [s for qid, s in plan.start_slot.items() if qid in pending and s > now]
    
                if future:
                    now = min(future)
                    jump = now - prev_now
                    num_idle_jumps += 1
                    total_idle_slots += int(max(0, jump))
                    self.logger.log(f"[t={prev_now}→{now}] IDLE jump Δsim={jump} slots pending={len(pending)}")
                    continue
    
                # No usable future start remains for pending queries -> plan is stale
                plan = optimiser.reoptimize(now_slot=now)
                num_reopts += 1
                planned_start_slot = dict(plan.start_slot)
                self.logger.log(f"[t={now}] pending={len(pending)} running={len(optimiser.running)}")
                continue
    
            # next finish event (DES reality)
            next_finish = min(r.actual_end_slot for r in optimiser.running.values())
            now = int(next_finish)
    
            finished_jobs = [r for r in optimiser.running.values() if r.actual_end_slot == next_finish]
            finished = [r.qid for r in finished_jobs]
    
            reopt_needed = self._should_reopt_after_finish(finished_jobs)
    
            for qid in finished:
                optimiser.mark_completed(qid=qid, finished_slot=now)
    
            self.logger.log(
                f"[t={prev_now}→{now}] FINISH n={len(finished)} Δsim={now-prev_now} "
                f"slots pending={len(pending)} running={len(optimiser.running)} reopt={reopt_needed}"
            )
    
            if reopt_needed:
                plan = optimiser.reoptimize(now_slot=now)
                num_reopts += 1
                planned_start_slot = dict(plan.start_slot)
                self.logger.log(f"[t={now}] REOPT pending={len(pending)} running={len(optimiser.running)}")
    
        wall_seconds = self.logger.time()
        self.logger.log(f"[DONE] scheduled={len(realised)} total={len(specs)}")
    
        planned_durations = optimiser.planned_durations()
        planned_cpu, planned_ram = optimiser.planned_resources()
    
        # Realised durations from realised schedule
        realised_durations = {qid: int(e - s) for qid, (s, e, _, _) in realised.items()}
    
        pm = optimiser.power_model
    
        planned_carbon = _planned_total_carbon(
            cp=cp,
            planned_start_slot=planned_start_slot,
            planned_durations=planned_durations,
            planned_cpu=planned_cpu,
            planned_ram=planned_ram,
            pm=pm,
        )
        realised_carbon = _realised_total_carbon(cp, realised, pm)
    
        total_sim_slots = int(now)
    
        return SchedulerResult(
            name=self.name,
            label=self.label,
            optimiser_name=optimiser.__class__.__name__,
            oracle_planning=self.oracle_planning,
            use_true_for_execution=self.use_true_for_execution,
            cp=cp,
            specs=specs,
            extra=self.extra,
            planned_start_slot=planned_start_slot,
            realised=realised,
            planned_durations=planned_durations,
            realised_durations=realised_durations,
            num_queries=len(specs),
            num_reopts=num_reopts,
            num_idle_jumps=num_idle_jumps,
            total_idle_slots=total_idle_slots,
            total_sim_slots=total_sim_slots,
            wall_seconds=float(wall_seconds),
            finish_slot=int(now),
            planned_carbon=float(planned_carbon),
            realised_carbon=float(realised_carbon),
        )

        
    def _should_reopt_after_finish(self, finished_jobs: List[RunningJob]) -> bool:
        if not finished_jobs:
            return False
    
        max_dur_err = 0.0
        max_cpu_err = 0.0
        max_ram_err = 0.0

        if self.reopt_threshold is None:
            return False

        thr = float(self.reopt_threshold)
    
        for rj in finished_jobs:
            planned_dur = max(1, int(rj.planned_end_slot - rj.start_slot))
            actual_dur = max(1, int(rj.actual_end_slot - rj.start_slot))
    
            dur_rel_err = abs(actual_dur - planned_dur) / planned_dur
            cpu_rel_err = abs(float(rj.actual_cpu) - float(rj.planned_cpu)) / max(1.0, float(rj.planned_cpu))
            ram_rel_err = abs(float(rj.actual_ram) - float(rj.planned_ram)) / max(1.0, float(rj.planned_ram))
    
            max_dur_err = max(max_dur_err, dur_rel_err)
            max_cpu_err = max(max_cpu_err, cpu_rel_err)
            max_ram_err = max(max_ram_err, ram_rel_err)
    
        return (
            max_dur_err > thr
            or max_cpu_err > thr
            or max_ram_err > thr
        )