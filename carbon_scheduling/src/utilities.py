from dataclasses import asdict
from typing import Dict, List, Tuple, Optional, Any
import numpy as np
import pandas as pd

from carbon_scheduling.src.scheduler import SchedulerResult
from carbon_scheduling.src.structs import QuerySpec

# schedule: qid -> (start_slot, end_slot, cpu, ram)
Schedule = Dict[str, Tuple[int, int, float, float]]

def _bind_penalties(penalties, cp):
    """Bind once (cache ci_ref etc.)"""
    if not penalties:
        return []
    return [p.bind(cp) for p in penalties]

def realised_schedule_from_res(res: SchedulerResult):
    return dict(res.realised)  # already qid -> (s,e,cpu,ram)

def print_schedule_summary(metrics: Dict[str, Any], top_k: int = 10) -> None:
    totals = metrics["totals"]
    rows = metrics["rows"]

    print("=== Schedule Summary ===")
    print(f"Queries:               {totals['n_queries']}")
    print(f"Planned carbon (gCO2): {totals['planned_carbon_gco2']:.4f}")
    print(f"Realised carbon (gCO2):{totals['realised_carbon_gco2']:.4f}")
    print(f"Carbon/query (gCO2):   {totals['carbon_per_query_gco2']:.6f}")
    print(f"Total penalty:         {totals['penalty_total']:.6f}")

    if totals["penalty_totals_by_name"]:
        print("\nPenalty totals by name:")
        for name, val in sorted(totals["penalty_totals_by_name"].items(), key=lambda kv: -kv[1]):
            print(f"  - {name}: {val:.6f}")

    # show “worst offenders”
    rows_by_pen = sorted(rows, key=lambda r: r["penalty_total"], reverse=True)[:top_k]
    print(f"\nTop {min(top_k, len(rows_by_pen))} penalties:")
    for r in rows_by_pen:
        print(
            f"  {r['qid']}: pen={r['penalty_total']:.6f}, "
            f"realised={r['realised_carbon_gco2']:.4f} gCO2, "
            f"start={r['start_slot']}, dur_act={r['dur_act_slots']}"
        )


def _ci_sum(cp, start: int, dur: int) -> float:
    s = int(max(0, start))
    e = int(min(int(cp.num_slots), s + int(max(1, dur))))
    if e <= s:
        e = s + 1
    if hasattr(cp, "ci_prefix") and cp.ci_prefix is not None:
        return float(cp.ci_prefix[e] - cp.ci_prefix[s])
    return float(np.sum(cp.ci[s:e]))

def _planned_duration_from_spec(q: QuerySpec) -> int:
    return int(max(1, round(float(q.dur_mean_slots_pred))))

def _power_from_spec(q: QuerySpec) -> float:
    return float(getattr(q, "power_kw", 0.150))

def comparison_df_from_absolute_results(
    results: dict[str, "SchedulerResult"],
    *,
    oracle_key: str = "oracle",
    sort_by: str = "realised_delta_gco2",
) -> pd.DataFrame:
    rows = []

    for label, res in results.items():
        cp = res.cp
        spec_by = {q.qid: q for q in res.specs}

        # Carbon totals: prefer values computed in experiment using scheduler.power_model
        planned_total = float(getattr(res, "planned_carbon", 0.0))
        realised_total = float(getattr(res, "realised_carbon", 0.0))

        # Makespans (keep existing logic)
        planned_makespan_slots = 0
        if res.planned_start_slot:
            min_s = min(int(s) for s in res.planned_start_slot.values())
            max_e = min_s
            for qid, s in res.planned_start_slot.items():
                q = spec_by[qid]
                d = int(res.planned_durations.get(qid, _planned_duration_from_spec(q)))
                max_e = max(max_e, int(s) + int(d))
            planned_makespan_slots = int(max_e - min_s)

        realised_makespan_slots = 0
        if res.realised:
            min_s = min(int(v[0]) for v in res.realised.values())
            max_e = min_s
            for _qid, (_s, e, _cpu_act, _ram_act) in res.realised.items():
                max_e = max(max_e, int(e))
            realised_makespan_slots = int(max_e - min_s)

        rows.append({
            "label": label,
            "oracle_planning": bool(res.oracle_planning),
            "true_execution": bool(res.use_true_for_execution),

            "n_queries": int(res.num_queries) if res.num_queries else int(len(res.specs)),

            "planned_gco2": float(planned_total),
            "realised_gco2": float(realised_total),
            "plan_error_gco2": float(realised_total - planned_total),

            "makespan_planned_slots": int(planned_makespan_slots),
            "makespan_realised_slots": int(realised_makespan_slots),
            "makespan_planned_s": float(planned_makespan_slots) * float(cp.slot_sec),
            "makespan_realised_s": float(realised_makespan_slots) * float(cp.slot_sec),

            # run diagnostics you already track
            "num_reopts": int(res.num_reopts),
            "idle_jumps": int(res.num_idle_jumps),
            "idle_slots": int(res.total_idle_slots),
            "wall_s": float(res.wall_seconds),
            "mip_s_total": float(res.mip_seconds_total),
        })

    df = pd.DataFrame(rows).set_index("label", drop=True)

    # Per-query
    df["planned_per_query_gco2"] = df["planned_gco2"] / df["n_queries"]
    df["realised_per_query_gco2"] = df["realised_gco2"] / df["n_queries"]

    # Oracle deltas
    if oracle_key in df.index:
        o_plan = float(df.loc[oracle_key, "planned_gco2"])
        o_real = float(df.loc[oracle_key, "realised_gco2"])
        df["planned_delta_gco2"] = df["planned_gco2"] - o_plan
        df["realised_delta_gco2"] = df["realised_gco2"] - o_real
        df["planned_delta_pct"] = 100.0 * df["planned_delta_gco2"] / max(1e-9, o_plan)
        df["realised_delta_pct"] = 100.0 * df["realised_delta_gco2"] / max(1e-9, o_real)
    else:
        df["planned_delta_gco2"] = np.nan
        df["realised_delta_gco2"] = np.nan
        df["planned_delta_pct"] = np.nan
        df["realised_delta_pct"] = np.nan

    if sort_by in df.columns:
        df = df.sort_values(sort_by, ascending=True)

    # round for display
    out = df.copy()
    for c in out.columns:
        if out[c].dtype.kind in "fc":
            out[c] = out[c].round(4)
    return out


def metrics_to_dataframe(metrics: Dict[str, Any]) -> pd.DataFrame:
    rows = metrics["rows"]
    # flatten penalty_by_name into separate columns
    all_pen_names = sorted({k for r in rows for k in r["penalty_by_name"].keys()})
    flat = []
    for r in rows:
        base = {k: v for k, v in r.items() if k != "penalty_by_name"}
        for name in all_pen_names:
            base[f"pen_{name}"] = float(r["penalty_by_name"].get(name, 0.0))
        flat.append(base)
    return pd.DataFrame(flat)
