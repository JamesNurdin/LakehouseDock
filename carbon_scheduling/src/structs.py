from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Tuple
import math
import time
import pandas as pd

from carbon_scheduling.src.carbon import CarbonProfile


@dataclass(frozen=True)
class PowerModel:
    """
    Map (cpu_units, ram_gb) -> average kW during the query.

    Interpretation: MAX_CPU and MAX_RAM describe a "capacity slice"
    whose power envelope is (p_idle_w, p_peak_w) plus optional RAM budget.
    """
    max_cpu: float = 32.0
    max_ram: float = 128.0

    # Choose reasonable defaults for your hardware/slice
    p_idle_w: float = 140.0
    p_peak_w: float = 360.0      # at cpu=max_cpu

    clamp: bool = False

    def power_kw(self, cpu: float, ram: float) -> float:
        u = cpu / self.max_cpu if self.max_cpu else 0.0
        m = ram / self.max_ram if self.max_ram else 0.0
        if self.clamp:
            u = max(0.0, min(1.0, u))
            m = max(0.0, min(1.0, m))
        p_w = self.p_idle_w + u * (self.p_peak_w - self.p_idle_w) + m *0.392
        return p_w / 1000.0


def attach_power_proxy(specs: list["QuerySpec"], pm: PowerModel, *, use_true: bool = False) -> list["QuerySpec"]:
    out = []
    for q in specs:
        cpu = q.cpu_true if use_true else q.cpu
        ram = q.ram_true if use_true else q.ram
        p_kw = pm.query_power_kw(cpu, ram)
        out.append(type(q)(**{**q.__dict__, "power_kw": p_kw}))
    return out

@dataclass(frozen=True)
class QuerySpec:
    qid: str

    priority: int
    submission_time: int

    # --- What the optimiser uses to plan ---
    dur_mean_slots_pred: int
    dur_std_slots_pred: int

    cpu_mean_pred: float
    cpu_std_pred: float

    ram_mean_pred: float
    ram_std_pred: float

    # --- What actually happens at execution time (oracle / simulator truth) ---
    dur_mean_slots_true: int
    dur_std_slots_true: int

    cpu_mean_true: float
    cpu_std_true: float

    ram_mean_true: float
    ram_std_true: float

    # Optional convenience: keep a per-query power proxy
    power_kw: float = 0.150

    @property
    def dur_slots(self) -> int:
        return int(self.dur_mean_slots_pred)

    @property
    def cpu(self) -> float:
        return float(self.cpu_mean_pred)

    @property
    def ram(self) -> float:
        return float(self.ram_mean_pred)

    @property
    def dur_slots_true(self) -> int:
        return int(self.dur_mean_slots_true)

    @property
    def cpu_true(self) -> float:
        return float(self.cpu_mean_true)

    @property
    def ram_true(self) -> float:
        return float(self.ram_mean_true)

    def eff_plan_values(self, *, k_dur: float = 0.0, k_cpu: float = 0.0, k_ram: float = 0.0):
        d = int(max(1, round(self.dur_mean_slots_pred + k_dur * self.dur_std_slots_pred)))
        cpu = float(self.cpu_mean_pred + k_cpu * self.cpu_std_pred)
        ram = float(self.ram_mean_pred + k_ram * self.ram_std_pred)
        return d, cpu, ram


@dataclass
class RunningJob:
    qid: str
    start_slot: int

    # what the MILP assumed when it started this job
    planned_end_slot: int
    planned_cpu: float
    planned_ram: float

    # what actually happens in the simulation
    actual_end_slot: int
    actual_cpu: float
    actual_ram: float



@dataclass
class Plan:
    start_slot: Dict[str, int]


@dataclass
class SchedulerResult:
    name: str
    label: str
    optimiser_name: str
    oracle_planning: bool
    use_true_for_execution: bool

    cp: CarbonProfile = field(repr=False)
    specs: List[QuerySpec] = field(repr=False)
    extra: Dict[str, Any] = field(default_factory=dict, repr=False)

    # Schedules as start slots (planned) and realised tuples
    planned_start_slot: Dict[str, int] = field(default_factory=dict, repr=False)
    realised: Dict[str, Tuple[int, int, float, float]] = field(default_factory=dict, repr=False)
    # qid -> (start_slot, end_slot, cpu_act, ram_act)

    # Derived durations
    planned_durations: Dict[str, int] = field(default_factory=dict, repr=False)
    realised_durations: Dict[str, int] = field(default_factory=dict, repr=False)

    # Timing + counters
    num_queries: int = 0
    num_reopts: int = 0
    num_idle_jumps: int = 0
    total_idle_slots: int = 0
    total_sim_slots: int = 0
    wall_seconds: float = 0.0

    # Convenience
    finish_slot: int = 0

    planned_carbon: float = 0.0
    realised_carbon: float = 0.0

    def schedule_dataframe(self, which: str = "realised", order_by: str = "start") -> pd.DataFrame:
        if which not in {"realised", "planned"}:
            raise ValueError("which must be 'realised' or 'planned'")

        rows = []
        if which == "realised":
            for qid, (s, e, cpu, ram) in self.realised.items():
                rows.append(
                    {
                        "query_id": qid,
                        "start_slot": int(s),
                        "end_slot": int(e),
                        "dur_slots": int(e - s),
                        "cpu": float(cpu),
                        "ram": float(ram),
                    }
                )
        else:
            for qid, s in self.planned_start_slot.items():
                d = int(self.planned_durations.get(qid, 0))
                rows.append(
                    {
                        "query_id": qid,
                        "start_slot": int(s),
                        "end_slot": int(s + d),
                        "dur_slots": int(d),
                    }
                )

        if order_by == "start":
            rows.sort(key=lambda r: r["start_slot"])
        elif order_by == "query_id":
            rows.sort(key=lambda r: r["query_id"])

        return pd.DataFrame(rows)

    def summary(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "label": self.label,
            "optimiser": self.optimiser_name,
            "oracle_planning": bool(self.oracle_planning),
            "use_true_for_execution": bool(self.use_true_for_execution),
            "num_queries": int(self.num_queries),
            "finish_slot": int(self.finish_slot),
            "sim_seconds": float(self.total_sim_slots * self.cp.slot_sec),
            "wall_seconds": float(self.wall_seconds),
            "num_reopts": int(self.num_reopts),
            "num_idle_jumps": int(self.num_idle_jumps),
            "total_idle_slots": int(self.total_idle_slots),
            "planned_carbon": float(self.planned_carbon),
            "realised_carbon": float(self.realised_carbon),
            **(self.extra or {}),
        }

    def __repr__(self) -> str:
        s = self.summary()
        return (
            f"SchedulerResult<{s['name']}>("
            f"label={s['label']}, "
            f"optimiser={s['optimiser']}, "
            f"queries={s['num_queries']}, "
            f"wall={s['wall_seconds']:.2f}s, "
            f"reopts={s['num_reopts']}, "
            f"mip={s['mip_seconds_total']:.2f}s, "
            f"idle_slots={s['total_idle_slots']})"
        )
        

class Logger():
    verbose: bool
    wall0: int
    
    def __init__(self, verbose):
        self.verbose = verbose
        self.wall0 = time.perf_counter()
    
    def time(self):
        return time.perf_counter() - self.wall0
    
    def log(self, msg: str) -> None:
        if not self.verbose:
            return
        wall = time.perf_counter() - self.wall0
        print(f"[wall={wall:8.2f}s] {msg}")