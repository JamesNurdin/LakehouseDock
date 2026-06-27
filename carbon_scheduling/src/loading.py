import math
from typing import List
import pandas as pd

from carbon_scheduling.src.structs import QuerySpec

def seconds_to_slots(seconds: float, slot_sec: float) -> int:
    return int(max(1, math.ceil(float(seconds) / float(slot_sec))))

def power_proxy_kw(cpu: float, ram: float, *, p_idle=0.0, p_cpu=0.02, p_ram=0.001) -> float:
    # Simple proxy: 20W per reserved core, 1W per GB
    return float(max(0.0, p_idle + p_cpu * cpu + p_ram * ram))

def df_to_queryspecs_pred_true(
    df: pd.DataFrame,
    *,
    slot_sec: float,
    cpu_cap: float,
    ram_cap: float,
    # runtime
    runtime_mean_pred_col: str = "runtime_mean_pred",
    runtime_std_pred_col: str = "runtime_std_pred",
    runtime_mean_true_col: str = "runtime_mean_true",
    runtime_std_true_col: str = "runtime_std_true",
    # cpu
    cpu_mean_pred_col: str = "cpu_mean_pred",
    cpu_std_pred_col: str = "cpu_std_pred",
    cpu_mean_true_col: str = "cpu_mean_true",
    cpu_std_true_col: str = "cpu_std_true",
    # ram
    ram_mean_pred_col: str = "ram_mean_pred",
    ram_std_pred_col: str = "ram_std_pred",
    ram_mean_true_col: str = "ram_mean_true",
    ram_std_true_col: str = "ram_std_true",

    priority: str = "priority",
    submission_time: str = "submission_time",
    
) -> List[QuerySpec]:
    specs: List[QuerySpec] = []

    def _ceil_clip(x: float, cap: float) -> float:
        # ensure >=1 and <=cap and integer-ish for feasibility in slot/resource space
        return float(min(cap, max(1.0, math.ceil(float(x)))))

    for _, row in df.iterrows():
        # ---- durations -> slots (mean/std for both pred and true) ----
        dur_mean_slots_pred = seconds_to_slots(float(row[runtime_mean_pred_col]), slot_sec)
        dur_std_slots_pred  = seconds_to_slots(float(row[runtime_std_pred_col]),  slot_sec)

        dur_mean_slots_true = seconds_to_slots(float(row[runtime_mean_true_col]), slot_sec)
        dur_std_slots_true  = seconds_to_slots(float(row[runtime_std_true_col]),  slot_sec)

        # Guard: std can become 0 slots after conversion; keep >=0 (or >=1 if you prefer)
        dur_std_slots_pred = max(0, int(dur_std_slots_pred))
        dur_std_slots_true = max(0, int(dur_std_slots_true))

        # ---- cpu/ram (mean/std for both pred and true) ----
        cpu_mean_pred = float(row[cpu_mean_pred_col])
        cpu_std_pred  = float(row[cpu_std_pred_col])
        cpu_mean_true = float(row[cpu_mean_true_col])
        cpu_std_true  = float(row[cpu_std_true_col])

        ram_mean_pred = float(row[ram_mean_pred_col])
        ram_std_pred  = float(row[ram_std_pred_col])
        ram_mean_true = float(row[ram_mean_true_col])
        ram_std_true  = float(row[ram_std_true_col])

        cpu_mean_pred_feas = _ceil_clip(cpu_mean_pred, cpu_cap)
        ram_mean_pred_feas = _ceil_clip(ram_mean_pred, ram_cap)

        cpu_mean_true_feas = _ceil_clip(cpu_mean_true, cpu_cap)
        ram_mean_true_feas = _ceil_clip(ram_mean_true, ram_cap)

        pkw = power_proxy_kw(cpu_mean_pred_feas, ram_mean_pred_feas)

        specs.append(
            QuerySpec(
                qid=str(row["q"]),
                priority=row[priority],
                submission_time=row[submission_time],
                dur_mean_slots_pred=int(dur_mean_slots_pred),
                dur_std_slots_pred=int(dur_std_slots_pred),
                cpu_mean_pred=cpu_mean_pred_feas,
                cpu_std_pred=float(cpu_std_pred),
                ram_mean_pred=ram_mean_pred_feas,
                ram_std_pred=float(ram_std_pred),
                dur_mean_slots_true=int(dur_mean_slots_true),
                dur_std_slots_true=int(dur_std_slots_true),
                cpu_mean_true=cpu_mean_true_feas,
                cpu_std_true=float(cpu_std_true),
                ram_mean_true=ram_mean_true_feas,
                ram_std_true=float(ram_std_true),
                power_kw=float(pkw),
            )
        )

    return specs