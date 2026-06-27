import numpy as np
import matplotlib.pyplot as plt
from typing import Dict, Tuple
import plotly.graph_objects as go
import plotly.io as pio
import pandas as pd

from pandas import DataFrame

pio.renderers.default = "notebook_connected"

def plot_ci_over_slots(carbon_profile, max_slots=None, figsize=(10, 4)):
    """
    Plot carbon intensity (gCO2/kWh) as a function of slot index.

    Parameters
    ----------
    carbon_profile : CarbonProfile
        Your existing CarbonProfile instance.

    max_slots : int or None
        If given, only plot the first `max_slots` slots.

    figsize : tuple
        Matplotlib figure size.
    """
    ci = carbon_profile.ci
    if max_slots is not None:
        ci = ci[:max_slots]

    x = np.arange(len(ci))

    plt.figure(figsize=figsize)
    plt.plot(x, ci)
    plt.xlabel("Slot index")
    plt.ylabel("CI (gCO₂/kWh)")
    plt.title("Carbon intensity over slots")
    plt.tight_layout()
    plt.show()

def plot_priority_distribution(df: pd.DataFrame, *, bins_score: int = 30) -> None:
    """
    Visualise discrete priority counts
    
    Expects columns: priority
    """

    pri = df["priority"].to_numpy()

    fig, axes = plt.subplots(1, 1, figsize=(14, 3.8))

    # --- discrete priority ---
    vals, counts = np.unique(pri, return_counts=True)
    axes.bar(vals, counts)
    axes.set_title("Discrete priority")
    axes.set_xlabel("priority (lower = higher priority)")
    axes.set_ylabel("count")

    plt.tight_layout()
    plt.show()
    

def _qid_to_priority_map(specs):
    return {s.qid: int(s.priority) for s in specs}


def plot_ci_and_schedule_aligned_static(
    *,
    cp,  # CarbonProfile
    results,  # SchedulerResult
    cpu_max: float,
    ram_max: float,
    title: str = "Schedule overlay on CI (slot-based)",
):
    schedule = dict(results.realised)  # qid -> (start_slot, end_slot, cpu, ram)

    ci = np.asarray(cp.ci, dtype=float)
    T = len(ci)
    t = np.arange(T)

    jobs = sorted(schedule.items(), key=lambda kv: int(kv[1][0]))

    # ===========================
    # FIGURE 1 — CI + lanes 
    # ===========================
    fig, ax1 = plt.subplots(figsize=(14, 4.5))
    ax1.plot(t, ci)
    ax1.set_xlim(0, T - 1)
    ax1.set_xlabel(f"Time (slots, slot_sec={cp.slot_sec:g}s)")
    ax1.set_ylabel("CI (gCO₂/kWh)")
    ax1.set_title(title)

    ax2 = ax1.twinx()
    ax2.set_yticks([])
    ax2.set_ylabel("Jobs (lanes)")

    lane_h = 0.8
    lane_gap = 0.25
    lane_total = lane_h + lane_gap

    for i, (qid, (s, e, cpu, ram)) in enumerate(jobs):
        s2 = max(0, int(s))
        e2 = min(T, int(e))
        if e2 <= s2:
            continue
        y = i * lane_total
        ax2.broken_barh([(s2, e2 - s2)], (y, lane_h), alpha=0.35)
        ax2.text(s2, y + lane_h / 2, qid, va="center", ha="left", fontsize=8)

    ax2.set_ylim(-0.5, max(1.0, len(jobs) * lane_total))
    plt.tight_layout()
    plt.show()

    # ===========================
    # FIGURE 1b — Priority spectrum lines
    # ===========================
    qid_to_priority = _qid_to_priority_map(results.specs)

    # priorities for normalization / colorbar
    pri_vals = np.array(list(qid_to_priority.values()), dtype=float)
    if pri_vals.size == 0:
        raise ValueError("results.specs is empty; cannot plot priority overlay.")

    pri_min = float(np.min(pri_vals))
    pri_max = float(np.max(pri_vals))
    norm = plt.Normalize(vmin=pri_min, vmax=pri_max)
    cmap = plt.cm.viridis  # spectrum

    fig_p, ax_ci = plt.subplots(figsize=(14, 4.5))
    ax_ci.plot(t, ci)
    ax_ci.set_xlim(0, T - 1)
    ax_ci.set_xlabel(f"Time (slots, slot_sec={cp.slot_sec:g}s)")
    ax_ci.set_ylabel("CI (gCO₂/kWh)")
    ax_ci.set_title("CI with priority-coloured realised overlay")

    # Overlay bars: use axvspan per job (like your screenshot's translucent blocks)
    for qid, (s, e, *_rest) in jobs:
        s2 = max(0, int(s))
        e2 = min(T, int(e))
        if e2 <= s2:
            continue

        pri = qid_to_priority.get(qid, None)
        if pri is None:
            continue

        ax_ci.axvspan(s2, e2, alpha=0.18, color=cmap(norm(pri)), linewidth=0)

    # colorbar
    sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm)
    sm.set_array([])
    cbar = plt.colorbar(sm, ax=ax_ci, pad=0.01)
    cbar.set_label("priority (lower = higher)")

    plt.tight_layout()
    plt.show()

    # ===========================
    # Build resource series (unchanged)
    # ===========================
    cpu_used = np.zeros(T, dtype=float)
    ram_used = np.zeros(T, dtype=float)

    for (s, e, cpu, ram) in schedule.values():
        s2 = max(0, int(s))
        e2 = min(T, int(e))
        if e2 <= s2:
            continue
        cpu_used[s2:e2] += float(cpu)
        ram_used[s2:e2] += float(ram)

    # ===========================
    # FIGURE 2 — CPU + CI 
    # ===========================
    fig_cpu, ax_cpu = plt.subplots(figsize=(14, 3.8))
    ax_cpu.plot(t, cpu_used, label="CPU used")
    ax_cpu.axhline(cpu_max, linestyle="--", label="CPU cap")
    ax_cpu.set_xlim(0, T - 1)
    ax_cpu.set_xlabel(f"Time (slots, slot_sec={cp.slot_sec:g}s)")
    ax_cpu.set_ylabel("CPU cores")
    ax_cpu.set_title("CPU utilisation + CI")

    ax_ci = ax_cpu.twinx()
    ax_ci.plot(t, ci, linestyle=":", label="CI")
    ax_ci.set_ylabel("CI (gCO₂/kWh)")

    h1, l1 = ax_cpu.get_legend_handles_labels()
    h2, l2 = ax_ci.get_legend_handles_labels()
    ax_cpu.legend(h1 + h2, l1 + l2, loc="upper right")

    plt.tight_layout()
    plt.show()

    # ===========================
    # FIGURE 3 — RAM + CI
    # ===========================
    fig_ram, ax_ram = plt.subplots(figsize=(14, 3.8))
    ax_ram.plot(t, ram_used, label="RAM used")
    ax_ram.axhline(ram_max, linestyle="--", label="RAM cap")
    ax_ram.set_xlim(0, T - 1)
    ax_ram.set_xlabel(f"Time (slots, slot_sec={cp.slot_sec:g}s)")
    ax_ram.set_ylabel("RAM (GB)")
    ax_ram.set_title("RAM utilisation + CI")

    ax_ci2 = ax_ram.twinx()
    ax_ci2.plot(t, ci, linestyle=":", label="CI")
    ax_ci2.set_ylabel("CI (gCO₂/kWh)")

    h1, l1 = ax_ram.get_legend_handles_labels()
    h2, l2 = ax_ci2.get_legend_handles_labels()
    ax_ram.legend(h1 + h2, l1 + l2, loc="upper right")

    plt.tight_layout()
    plt.show()


def plot_interactive_resource_by_query(
    *,
    cp,  # CarbonProfile
    schedule: Dict[str, Tuple[int, int, float, float]],
    cpu_max: float,
    ram_max: float,
    ci_on: str = "y2",        # "y2" (right axis) or "y" (left)
    ci_style: str = "dot",    # dotted CI line
):
    ci = np.asarray(cp.ci, dtype=float)
    T = len(ci)
    t = np.arange(T)

    jobs = sorted(schedule.items(), key=lambda kv: int(kv[1][0]))

    def _segment_series(value: float, s2: int, e2: int):
        """
        Return y as object array with None outside [s2,e2), value inside.
        This prevents stackgroup "fills" from appearing where the query isn't running.
        """
        y = np.full(T, None, dtype=object)
        y[s2:e2] = float(value)
        return y

    def _add_ci_trace(fig: go.Figure):
        # CI trace on right axis by default (keeps resources readable)
        fig.add_trace(
            go.Scatter(
                x=t,
                y=ci,
                name="CI",
                yaxis=ci_on,
                mode="lines",
                line=dict(dash=ci_style, width=2),
                hovertemplate=(
                    "<b>CI</b><br>"
                    "t=%{x}<br>"
                    "CI=%{y:.2f} gCO₂/kWh"
                    "<extra></extra>"
                ),
            )
        )

        if ci_on == "y2":
            fig.update_layout(
                yaxis2=dict(
                    title="CI (gCO₂/kWh)",
                    overlaying="y",
                    side="right",
                    showgrid=False,
                )
            )

    # ---------- CPU FIG ----------
    fig_cpu = go.Figure()

    for qid, (s, e, cpu, ram) in jobs:
        s2 = max(0, int(s))
        e2 = min(T, int(e))
        if e2 <= s2:
            continue

        y = _segment_series(cpu, s2, e2)

        fig_cpu.add_trace(
            go.Scatter(
                x=t,
                y=y,
                stackgroup="cpu",
                name=qid,
                mode="none",        # hover on fill
                hoveron="fills",
                opacity=0.5,
                line=dict(width=0.5),
                hovertemplate=(
                    f"<b>{qid}</b><br>"
                    f"CPU: {float(cpu):.2f}<br>"
                    f"Start: {s2}<br>"
                    f"End: {e2}<br>"
                    f"Duration: {e2 - s2} slots"
                    "<extra></extra>"
                ),
                connectgaps=False,
            )
        )

    # CPU cap
    fig_cpu.add_hline(
        y=cpu_max,
        line_dash="dash",
        annotation_text="CPU cap",
        annotation_position="top left",
    )

    # Add CI
    _add_ci_trace(fig_cpu)

    fig_cpu.update_layout(
        title=f"CPU utilisation by query + CI (slot_sec={cp.slot_sec:g}s)",
        xaxis_title="Time (slots)",
        yaxis_title="CPU cores",
        hovermode="closest",   # only the region you’re on
        legend=dict(orientation="h"),
    )
    fig_cpu.show()

    # ---------- RAM FIG ----------
    fig_ram = go.Figure()

    for qid, (s, e, cpu, ram) in jobs:
        s2 = max(0, int(s))
        e2 = min(T, int(e))
        if e2 <= s2:
            continue

        y = _segment_series(ram, s2, e2)

        fig_ram.add_trace(
            go.Scatter(
                x=t,
                y=y,
                stackgroup="ram",
                name=qid,
                mode="none",
                hoveron="fills",
                opacity=0.5,
                line=dict(width=0.5),
                hovertemplate=(
                    f"<b>{qid}</b><br>"
                    f"RAM: {float(ram):.2f} GB<br>"
                    f"Start: {s2}<br>"
                    f"End: {e2}<br>"
                    f"Duration: {e2 - s2} slots"
                    "<extra></extra>"
                ),
                connectgaps=False,
            )
        )

    # RAM cap
    fig_ram.add_hline(
        y=ram_max,
        line_dash="dash",
        annotation_text="RAM cap",
        annotation_position="top left",
    )

    # Add CI
    _add_ci_trace(fig_ram)

    fig_ram.update_layout(
        title=f"RAM utilisation by query + CI (slot_sec={cp.slot_sec:g}s)",
        xaxis_title="Time (slots)",
        yaxis_title="RAM (GB)",
        hovermode="closest",
        legend=dict(orientation="h"),
    )
    fig_ram.show()

def plot_queries_for_inspection(df: DataFrame):
    df_plot = (df.sort_values("runtime_median_true").reset_index(drop=True))
    x = np.arange(len(df_plot))

    # Plot: predicted mean with error bars and true median as points
    plt.figure(figsize=(12, 5))
    plt.errorbar(x, df_plot["runtime_mean_pred"], yerr=df_plot["runtime_std_pred"], fmt="o", capsize=4)
    plt.scatter(x, df_plot["runtime_median_true"], marker="x")
    plt.xticks(x, df_plot["q"], rotation=90)
    plt.ylabel("Runtime")
    plt.title("Predicted runtime mean ± std vs True median runtime")
    plt.tight_layout()
    plt.show()