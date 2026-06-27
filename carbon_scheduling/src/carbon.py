from typing import Any, Dict, List, Optional, Tuple

import numpy as np
import pandas as pd


def _compute_end_from_duration(
    start_ts: pd.Timestamp,
    *,
    duration_days: int = 0,
    duration_hours: int = 0,
    duration_minutes: int = 0,
    duration: Optional[pd.Timedelta] = None,
) -> pd.Timestamp:
    if duration is not None:
        if any([duration_days, duration_hours, duration_minutes]):
            raise ValueError("Provide either `duration` or (duration_days/hours/minutes), not both.")
        td = pd.Timedelta(duration)
    else:
        td = pd.Timedelta(days=duration_days, hours=duration_hours, minutes=duration_minutes)

    if td <= pd.Timedelta(0):
        raise ValueError(f"Duration must be > 0, got {td}.")
    return start_ts + td


def load_carbon_timeseries(
    csv_path: str,
    use_lifecycle: bool = False,
    start: Optional[str] = None,
    end: Optional[str] = None,
    *,
    # New: specify horizon as a duration instead of hard-coding end date/time
    duration_days: int = 0,
    duration_hours: int = 0,
    duration_minutes: int = 0,
    duration: Optional[pd.Timedelta] = None,
) -> Tuple[pd.DataFrame, np.ndarray, float, float]:
    df = pd.read_csv(csv_path)

    df["Datetime (UTC)"] = pd.to_datetime(df["Datetime (UTC)"])
    df = df.sort_values("Datetime (UTC)").reset_index(drop=True)

    if len(df) < 2:
        raise ValueError("Not enough rows in CSV to infer time step")

    # Anchor start
    start_ts = pd.to_datetime(start) if start is not None else pd.Timestamp(df["Datetime (UTC)"].iloc[0])

    # Determine end (priority: explicit end > duration > no end)
    if end is not None:
        end_ts = pd.to_datetime(end)
    else:
        has_duration = (duration is not None) or any([duration_days, duration_hours, duration_minutes])
        end_ts = _compute_end_from_duration(
            start_ts,
            duration_days=duration_days,
            duration_hours=duration_hours,
            duration_minutes=duration_minutes,
            duration=duration,
        ) if has_duration else None

    # Filter
    df = df[df["Datetime (UTC)"] >= start_ts]
    if end_ts is not None:
        df = df[df["Datetime (UTC)"] < end_ts]

    df = df.reset_index(drop=True)

    if len(df) < 2:
        raise ValueError("Not enough rows after filtering to infer time step (need at least 2).")

    df = df.rename(
        columns={
            "Carbon intensity gCO₂eq/kWh (direct)": "ci_direct",
            "Carbon intensity gCO₂eq/kWh (Life cycle)": "ci_lifecycle",
        }
    )

    col = "ci_lifecycle" if use_lifecycle else "ci_direct"
    if col not in df.columns:
        raise KeyError(f"Column '{col}' not found. Available: {list(df.columns)}")

    ci = df[col].to_numpy(dtype=float)

    # robust timestep inference (median diff)
    dts = df["Datetime (UTC)"].diff().dt.total_seconds().dropna().to_numpy()
    slot_sec = float(np.median(dts))
    if not np.allclose(dts, slot_sec, rtol=0, atol=1e-6):
        print("[CI] Warning: non-uniform timestep detected; using median step.")

    dt_hours = slot_sec / 3600.0
    return df, ci, slot_sec, dt_hours


def upsample_ci_repeat(ci: np.ndarray, old_slot_sec: float, new_slot_sec: float) -> Tuple[np.ndarray, float, float]:
    if new_slot_sec > old_slot_sec:
        raise ValueError("new_slot_sec must be <= old_slot_sec")

    ratio = float(old_slot_sec) / float(new_slot_sec)
    factor = int(round(ratio))
    if not np.isclose(ratio, factor, rtol=1e-9, atol=1e-9):
        raise ValueError(
            f"old_slot_sec ({old_slot_sec}) must be an integer multiple of "
            f"new_slot_sec ({new_slot_sec}); got ratio={ratio}"
        )

    ci_new = np.repeat(ci, factor)
    dt_hours_new = float(new_slot_sec) / 3600.0
    return ci_new, float(new_slot_sec), dt_hours_new


def make_ci_prefix(ci: np.ndarray) -> np.ndarray:
    return np.concatenate([[0.0], np.cumsum(ci.astype(float))])


class CarbonProfile:
    def __init__(self, ci: np.ndarray, slot_sec: float, df: Optional[pd.DataFrame] = None):
        self.ci = np.asarray(ci, dtype=float)
        self.slot_sec = float(slot_sec)
        self.dt_hours = self.slot_sec / 3600.0
        self.df = df
        self.ci_prefix = make_ci_prefix(self.ci)

    @classmethod
    def from_csv(
        cls,
        csv_path: str,
        use_lifecycle: bool = False,
        start: Optional[str] = None,
        end: Optional[str] = None,
        *,
        duration_days: int = 0,
        duration_hours: int = 0,
        duration_minutes: int = 0,
        duration: Optional[pd.Timedelta] = None,
        upsample_to_sec: int = 60,
    ) -> "CarbonProfile":
        df_ci, ci_raw, slot_sec_raw, _ = load_carbon_timeseries(
            csv_path,
            use_lifecycle=use_lifecycle,
            start=start,
            end=end,
            duration_days=duration_days,
            duration_hours=duration_hours,
            duration_minutes=duration_minutes,
            duration=duration,
        )
        ci, slot_sec, _ = upsample_ci_repeat(ci_raw, slot_sec_raw, upsample_to_sec)
        return cls(ci=ci, slot_sec=slot_sec, df=df_ci)

    @property
    def num_slots(self) -> int:
        return int(len(self.ci))

    def ci_mean(self) -> float:
        return float(np.mean(self.ci)) if self.num_slots > 0 else 0.0

    def ci_std(self, ddof: int = 0) -> float:
        return float(np.std(self.ci, ddof=ddof)) if self.num_slots > 0 else 0.0

    def ci_cov(self, ddof: int = 0, eps: float = 1e-12) -> float:
        mu = self.ci_mean()
        if abs(mu) <= eps:
            return 0.0
        return float(self.ci_std(ddof=ddof) / mu)

    def ensure_horizon(self, required_slots: int, *, pad: str = "last") -> None:
        required_slots = int(required_slots)
        if required_slots <= self.num_slots:
            return

        extra = required_slots - self.num_slots

        if pad == "last":
            fill = float(self.ci[-1])
        elif pad == "mean":
            fill = float(np.mean(self.ci))
        elif pad == "zero":
            fill = 0.0
        else:
            raise ValueError(f"Unknown pad='{pad}'")

        extra_ci = np.full(extra, fill, dtype=float)
        self.ci = np.concatenate([self.ci, extra_ci], axis=0)
        self.ci_prefix = make_ci_prefix(self.ci)


def _carbon_for_interval(cp: CarbonProfile, s: int, e: int, pkw: float) -> float:
    s = int(max(0, s))
    e = int(min(e, len(cp.ci_prefix) - 1))
    if e <= s:
        return 0.0
    dt = float(cp.dt_hours)
    ci_sum = float(cp.ci_prefix[e] - cp.ci_prefix[s])
    return float(ci_sum * pkw * dt)

def _planned_total_carbon(
    cp: CarbonProfile,
    planned_start_slot: Dict[str, int],
    planned_durations: Dict[str, int],
    planned_cpu: Dict[str, float],
    planned_ram: Dict[str, float],
    pm,
) -> float:
    total = 0.0

    for qid, s in planned_start_slot.items():
        d = int(planned_durations.get(qid, 0))
        if d <= 0:
            continue

        cpu = float(planned_cpu.get(qid, 0.0))
        ram = float(planned_ram.get(qid, 0.0))
        if cpu <= 0.0 or ram <= 0.0:
            continue

        e = int(s + d)
        pkw = float(pm.power_kw(cpu, ram))
        total += _carbon_for_interval(cp, int(s), int(e), pkw)

    return float(total)

def _realised_total_carbon(cp: CarbonProfile, realised: Dict[str, Tuple[int, int, float, float]], pm) -> float:
    total = 0.0
    for qid, (s, e, cpu, ram) in realised.items():
        pkw = float(pm.power_kw(float(cpu), float(ram)))
        total += _carbon_for_interval(cp, int(s), int(e), pkw)
    return float(total)