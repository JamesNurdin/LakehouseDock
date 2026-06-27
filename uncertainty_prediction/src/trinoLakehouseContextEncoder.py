from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, Iterable, List, Optional

import numpy as np
import pandas as pd


# -----------------------------------------------------------------------------
# Defaults
# -----------------------------------------------------------------------------

CONTEXT_FEATURE_COLS = [
    "cpu_speed_st_events_per_second",
    "cpu_speed_mt_events_per_second",
    "ram_speed_gb_s",
    "ceph_io_sequ_read_iops",
    "ceph_io_sequ_read_bw_mb",
    "ceph_io_sequ_read_lat_us",
]

CONTEXT_LOG_COLS = [
    "ceph_io_sequ_read_iops",
    "ceph_io_sequ_read_bw_mb",
    "ceph_io_sequ_read_lat_us",
]

ESTIMATE_KEYS = [
    "outputRowCount",
    "outputSizeInBytes",
    "cpuCost",
    "memoryCost",
    "networkCost",
]


# -----------------------------------------------------------------------------
# Query-plan pressure extraction
# -----------------------------------------------------------------------------

def _safe_float(x: Any) -> float:
    """
    Convert estimate values to float.

    Values such as 'NaN', None, or invalid strings become np.nan.
    """
    try:
        v = float(x)
    except Exception:
        return np.nan

    return v if np.isfinite(v) else np.nan


def _iter_node_estimates(node: Dict[str, Any]):
    estimates = node.get("estimates", [])

    if not isinstance(estimates, list):
        return

    for est in estimates:
        if isinstance(est, dict):
            yield est


def _node_name(node: Dict[str, Any]) -> str:
    return str(node.get("name", "")).lower()


def _estimate_sum_for_node(node: Dict[str, Any], key: str) -> float:
    vals = []

    for est in _iter_node_estimates(node):
        v = _safe_float(est.get(key, np.nan))
        if np.isfinite(v):
            vals.append(v)

    return float(np.sum(vals)) if vals else 0.0


def _estimate_count_for_node(node: Dict[str, Any]) -> tuple[int, int]:
    """
    Return:
        finite_estimate_values, total_estimate_values
    """
    finite = 0
    total = 0

    for est in _iter_node_estimates(node):
        for key in ESTIMATE_KEYS:
            if key in est:
                total += 1
                v = _safe_float(est.get(key))
                if np.isfinite(v):
                    finite += 1

    return finite, total


def extract_query_pressure_features(plan: Dict[str, Any]) -> pd.Series:
    """
    Extract coarse query-pressure features from a Trino plan dictionary.

    These are not intended to replace the plan embedding. They provide
    interpretable query-level pressure features used for query-context
    interaction terms.
    """
    nodes = plan.get("nodes", {})
    edges = plan.get("edges", [])

    if not isinstance(nodes, dict):
        raise ValueError("Plan dictionary missing valid 'nodes' mapping.")

    total_cpu = 0.0
    total_mem = 0.0
    total_net = 0.0
    total_rows = 0.0
    total_bytes = 0.0

    scan_cpu = 0.0
    scan_bytes = 0.0
    join_cpu = 0.0
    join_mem = 0.0
    sort_cpu = 0.0
    agg_cpu = 0.0
    exchange_net = 0.0

    n_nodes = 0
    n_scan = 0
    n_join = 0
    n_sort = 0
    n_agg = 0
    n_exchange = 0
    n_remote = 0

    finite_estimates = 0
    total_estimates = 0

    for _, node in nodes.items():
        if not isinstance(node, dict):
            continue

        n_nodes += 1
        name = _node_name(node)

        cpu = _estimate_sum_for_node(node, "cpuCost")
        mem = _estimate_sum_for_node(node, "memoryCost")
        net = _estimate_sum_for_node(node, "networkCost")
        rows = _estimate_sum_for_node(node, "outputRowCount")
        size = _estimate_sum_for_node(node, "outputSizeInBytes")

        total_cpu += cpu
        total_mem += mem
        total_net += net
        total_rows += rows
        total_bytes += size

        finite, total = _estimate_count_for_node(node)
        finite_estimates += finite
        total_estimates += total

        is_scan = "scan" in name
        is_join = "join" in name
        is_sort = "sort" in name or "merge" in name
        is_agg = "aggregate" in name
        is_exchange = "exchange" in name or "remote" in name

        if is_scan:
            n_scan += 1
            scan_cpu += cpu
            scan_bytes += size

        if is_join:
            n_join += 1
            join_cpu += cpu
            join_mem += mem

        if is_sort:
            n_sort += 1
            sort_cpu += cpu

        if is_agg:
            n_agg += 1
            agg_cpu += cpu

        if is_exchange:
            n_exchange += 1
            exchange_net += net

        if "remote" in name:
            n_remote += 1

    n_remote_edges = sum(
        1
        for e in edges
        if len(e) >= 3 and str(e[2]).lower() == "remote"
    )

    missing_estimate_ratio = (
        1.0 - (finite_estimates / total_estimates)
        if total_estimates > 0
        else 1.0
    )

    return pd.Series(
        {
            "qp_total_cpu": np.log1p(total_cpu),
            "qp_total_memory": np.log1p(total_mem),
            "qp_total_network": np.log1p(total_net),
            "qp_total_rows": np.log1p(total_rows),
            "qp_total_bytes": np.log1p(total_bytes),

            "qp_scan_pressure": np.log1p(scan_cpu + scan_bytes + n_scan),
            "qp_join_pressure": np.log1p(join_cpu + join_mem + n_join),
            "qp_sort_pressure": np.log1p(sort_cpu + n_sort),
            "qp_aggregate_pressure": np.log1p(agg_cpu + n_agg),
            "qp_exchange_pressure": np.log1p(
                exchange_net + n_exchange + n_remote + n_remote_edges
            ),

            "qp_n_nodes": np.log1p(n_nodes),
            "qp_n_scan": np.log1p(n_scan),
            "qp_n_join": np.log1p(n_join),
            "qp_n_sort": np.log1p(n_sort),
            "qp_n_aggregate": np.log1p(n_agg),
            "qp_n_exchange": np.log1p(n_exchange),
            "qp_n_remote": np.log1p(n_remote),
            "qp_n_remote_edges": np.log1p(n_remote_edges),

            "qp_missing_estimate_ratio": missing_estimate_ratio,
        },
        dtype=float,
    )


@dataclass
class QueryPressureReference:
    mean_: pd.Series
    std_: pd.Series

    @property
    def feature_names(self) -> List[str]:
        return list(self.mean_.index)


def fit_query_pressure_reference(
    plans_by_query: Dict[str, Dict[str, Any]],
    *,
    train_qids: Iterable[str],
    eps: float = 1e-8,
) -> QueryPressureReference:
    """
    Fit query-pressure normalisation on training query plans only.
    """
    rows = []

    for q in train_qids:
        q = str(q)
        if q not in plans_by_query:
            continue

        rows.append(extract_query_pressure_features(plans_by_query[q]))

    if not rows:
        raise ValueError("No valid query pressure features found for training qids.")

    df = pd.DataFrame(rows)
    df = df.replace([np.inf, -np.inf], np.nan).fillna(0.0)

    mean_ = df.mean(axis=0)
    std_ = df.std(axis=0).replace(0.0, 1.0).fillna(1.0)
    std_ = std_.where(std_.abs() >= eps, 1.0)

    return QueryPressureReference(mean_=mean_, std_=std_)


def transform_query_pressure(
    plan: Dict[str, Any],
    ref: QueryPressureReference,
) -> pd.Series:
    """
    Extract and standardise query-pressure features.
    """
    s = extract_query_pressure_features(plan)
    s = s.reindex(ref.feature_names)
    s = s.replace([np.inf, -np.inf], np.nan).fillna(0.0)
    return (s - ref.mean_) / ref.std_


# -----------------------------------------------------------------------------
# LakehouseContextEncoder
# -----------------------------------------------------------------------------

@dataclass
class LakehouseContextEncoder:
    """
    Run-level lakehouse context encoder.

    The encoder represents each query run using:
        1. Mean node-relative context state.
        2. Absolute accumulated node-relative deviation.
        3. Global context deviation scores.
        4. Query-conditioned context interaction scores.

    Node-relative scaling is fitted using training profiles only. Each node row
    is standardised relative to its own group, usually node_name. This avoids
    treating naturally faster/slower hardware as abnormal simply because it
    differs from the cluster-wide average.
    """

    feature_cols: List[str]
    log_cols: List[str]
    group_col: str

    include_abs: bool
    include_delta: bool
    include_query_context: bool
    include_sum_delta: bool

    min_group_rows: int

    global_mean_: np.ndarray
    global_std_: np.ndarray
    group_mean_: Dict[str, np.ndarray]
    group_std_: Dict[str, np.ndarray]
    pressure_ref_: QueryPressureReference

    feature_names_: Optional[List[str]] = None

    # -------------------------------------------------------------------------
    # Fitting
    # -------------------------------------------------------------------------

    @classmethod
    def fit_from_train_profiles(
        cls,
        *,
        profiles_by_run: Dict[str, pd.DataFrame],
        plans_by_query: Dict[str, Dict[str, Any]],
        train_query_run_ids: Iterable[str],
        train_qids: Iterable[str],
        feature_cols: List[str] = CONTEXT_FEATURE_COLS,
        log_cols: List[str] = CONTEXT_LOG_COLS,
        group_col: str = "node_name",
        min_group_rows: int = 3,
        include_abs: bool = True,
        include_delta: bool = True,
        include_query_context: bool = True,
        include_sum_delta: bool = False,
        eps: float = 1e-8,
    ) -> "LakehouseContextEncoder":
        """
        Fit node-relative profile references and query-pressure references.

        Parameters
        ----------
        profiles_by_run:
            query_run_id -> profile DataFrame.

        plans_by_query:
            query_id -> Trino plan dictionary.

        train_query_run_ids:
            Query-run IDs used to fit node/profile context statistics.

        train_qids:
            Query IDs used to fit query-pressure statistics.

        include_sum_delta:
            Whether to include signed accumulated deviation in the final context
            embedding. Usually False when the same set of profiled nodes appears
            in every run, because sum_delta becomes redundant with mean_abs.
        """
        feature_cols = list(feature_cols)
        log_cols = list(log_cols)
        train_query_run_ids = [str(x) for x in train_query_run_ids]

        frames: List[pd.DataFrame] = []

        for qrid in train_query_run_ids:
            if qrid not in profiles_by_run:
                continue

            df = profiles_by_run[qrid]

            if df is None or df.empty:
                continue

            if group_col not in df.columns:
                raise ValueError(
                    f"Missing group_col={group_col!r} in profile DataFrame."
                )

            missing = [c for c in feature_cols if c not in df.columns]
            if missing:
                raise ValueError(f"Profile DataFrame missing context columns: {missing}")

            work = df[[group_col] + feature_cols].copy()

            for col in feature_cols:
                work[col] = pd.to_numeric(work[col], errors="coerce")

            work = (
                work
                .replace([np.inf, -np.inf], np.nan)
                .dropna(subset=feature_cols + [group_col])
            )

            for col in log_cols:
                if col in work.columns:
                    values = work[col].to_numpy(dtype=float)
                    work[col] = np.log1p(np.clip(values, a_min=0.0, a_max=None))

            if not work.empty:
                frames.append(work)

        if not frames:
            raise ValueError("No valid training profile rows found.")

        all_df = pd.concat(frames, ignore_index=True)

        X_all = all_df[feature_cols].to_numpy(dtype=float)

        global_mean = np.mean(X_all, axis=0)
        global_std = np.std(X_all, axis=0)
        global_std = np.where(global_std < eps, 1.0, global_std)

        group_mean: Dict[str, np.ndarray] = {}
        group_std: Dict[str, np.ndarray] = {}

        for group_value, gdf in all_df.groupby(group_col):
            if len(gdf) < min_group_rows:
                continue

            X_g = gdf[feature_cols].to_numpy(dtype=float)

            mean_g = np.mean(X_g, axis=0)
            std_g = np.std(X_g, axis=0)
            std_g = np.where(std_g < eps, 1.0, std_g)

            group_key = str(group_value)
            group_mean[group_key] = mean_g
            group_std[group_key] = std_g

        pressure_ref = fit_query_pressure_reference(
            plans_by_query,
            train_qids=train_qids,
            eps=eps,
        )

        enc = cls(
            feature_cols=feature_cols,
            log_cols=log_cols,
            group_col=group_col,
        
            include_abs=bool(include_abs),
            include_delta=bool(include_delta),
            include_query_context=bool(include_query_context),
            include_sum_delta=bool(include_sum_delta),
        
            min_group_rows=int(min_group_rows),
            global_mean_=global_mean,
            global_std_=global_std,
            group_mean_=group_mean,
            group_std_=group_std,
            pressure_ref_=pressure_ref,
            feature_names_=None,
        )

        # Infer stable feature order from the first valid training example.
        for qrid in train_query_run_ids:
            if qrid not in profiles_by_run:
                continue

            profile_df = profiles_by_run[qrid]
            query_name = _query_name_from_profile_df(profile_df)

            if query_name is None or query_name not in plans_by_query:
                continue

            s = enc.encode_profile_as_series(
                profile_df=profile_df,
                plan=plans_by_query[query_name],
            )

            enc.feature_names_ = list(s.index)
            break

        if enc.feature_names_ is None:
            raise ValueError("Could not infer LakehouseContextEncoder feature names.")

        return enc

    # -------------------------------------------------------------------------
    # Metadata helpers
    # -------------------------------------------------------------------------

    @staticmethod
    def _query_name_from_profile_df(df: pd.DataFrame) -> str | None:
        return _query_name_from_profile_df(df)

    # -------------------------------------------------------------------------
    # Profile transform
    # -------------------------------------------------------------------------

    def _profile_to_group_relative_context_abs(self, df: pd.DataFrame) -> np.ndarray:
        """
        Convert a profile DataFrame into node/group-relative standardised rows.

        Each row is normalised using its own group reference when available:

            (x_i - mean_group(i)) / std_group(i)

        If a group was unseen or had too few rows during training, the global
        fallback reference is used.
        """
        if self.group_col not in df.columns:
            raise ValueError(
                f"Profile DataFrame missing group_col={self.group_col!r}."
            )

        missing = [c for c in self.feature_cols if c not in df.columns]
        if missing:
            raise ValueError(f"Profile DataFrame missing context columns: {missing}")

        work = df[[self.group_col] + self.feature_cols].copy()

        for col in self.feature_cols:
            work[col] = pd.to_numeric(work[col], errors="coerce")

        work = (
            work
            .replace([np.inf, -np.inf], np.nan)
            .dropna(subset=self.feature_cols + [self.group_col])
        )

        for col in self.log_cols:
            if col in work.columns:
                values = work[col].to_numpy(dtype=float)
                work[col] = np.log1p(np.clip(values, a_min=0.0, a_max=None))

        if work.empty:
            raise ValueError("No valid numeric context rows found.")

        rows: List[np.ndarray] = []

        for _, row in work.iterrows():
            group_key = str(row[self.group_col])
            x = row[self.feature_cols].to_numpy(dtype=float)

            mean = self.group_mean_.get(group_key, self.global_mean_)
            std = self.group_std_.get(group_key, self.global_std_)

            rows.append((x - mean) / std)

        return np.vstack(rows)

    # -------------------------------------------------------------------------
    # Context pieces
    # -------------------------------------------------------------------------

    def _mean_pool_context_abs(self, context_abs: np.ndarray) -> pd.Series:
        values = np.mean(context_abs, axis=0)

        return pd.Series(
            values,
            index=[f"ctx_mean_abs_{c}" for c in self.feature_cols],
            dtype=float,
        )

    def _sum_pool_context_delta(self, context_abs: np.ndarray) -> pd.Series:
        values = np.sum(context_abs, axis=0)

        return pd.Series(
            values,
            index=[f"ctx_sum_delta_{c}" for c in self.feature_cols],
            dtype=float,
        )

    def _sum_pool_abs_context_delta(self, context_abs: np.ndarray) -> pd.Series:
        values = np.sum(np.abs(context_abs), axis=0)

        return pd.Series(
            values,
            index=[f"ctx_sum_abs_delta_{c}" for c in self.feature_cols],
            dtype=float,
        )

    @staticmethod
    def _global_deviation_scores(
        mean_abs: pd.Series,
        sum_delta: pd.Series,
        sum_abs_delta: pd.Series,
    ) -> pd.Series:
        mean_vec = mean_abs.to_numpy(dtype=float)
        sum_delta_vec = sum_delta.to_numpy(dtype=float)
        sum_abs_delta_vec = sum_abs_delta.to_numpy(dtype=float)

        return pd.Series(
            {
                "ctx_global_mean_norm_l2":
                    float(np.linalg.norm(mean_vec, ord=2)),

                "ctx_global_sum_delta_norm_l2":
                    float(np.linalg.norm(sum_delta_vec, ord=2)),

                "ctx_global_sum_abs_delta_norm_l2":
                    float(np.linalg.norm(sum_abs_delta_vec, ord=2)),

                "ctx_global_mean_abs_avg":
                    float(np.mean(np.abs(mean_vec))),

                "ctx_global_sum_abs_delta_avg":
                    float(np.mean(sum_abs_delta_vec)),
            },
            dtype=float,
        )

    @staticmethod
    def _derive_context_scores_for_interaction(
        mean_abs: pd.Series,
        sum_abs_delta: pd.Series,
    ) -> pd.Series:
        def get_mean(col: str) -> float:
            return float(mean_abs.get(f"ctx_mean_abs_{col}", 0.0))

        def get_sum_abs(col: str) -> float:
            return float(sum_abs_delta.get(f"ctx_sum_abs_delta_{col}", 0.0))

        cpu_st = get_mean("cpu_speed_st_events_per_second")
        cpu_mt = get_mean("cpu_speed_mt_events_per_second")
        ram = get_mean("ram_speed_gb_s")
        ceph_iops = get_mean("ceph_io_sequ_read_iops")
        ceph_bw = get_mean("ceph_io_sequ_read_bw_mb")
        ceph_lat = get_mean("ceph_io_sequ_read_lat_us")

        cpu_unusual = 0.5 * (
            get_sum_abs("cpu_speed_st_events_per_second")
            + get_sum_abs("cpu_speed_mt_events_per_second")
        )

        ram_unusual = get_sum_abs("ram_speed_gb_s")

        storage_unusual = (
            get_sum_abs("ceph_io_sequ_read_iops")
            + get_sum_abs("ceph_io_sequ_read_bw_mb")
            + get_sum_abs("ceph_io_sequ_read_lat_us")
        ) / 3.0

        return pd.Series(
            {
                "ctx_cpu_score": 0.5 * (cpu_st + cpu_mt),
                "ctx_cpu_st_score": cpu_st,
                "ctx_cpu_mt_score": cpu_mt,
                "ctx_ram_score": ram,
                "ctx_storage_iops_score": ceph_iops,
                "ctx_storage_bw_score": ceph_bw,
                "ctx_storage_latency_risk": ceph_lat,

                "ctx_cpu_unusualness": cpu_unusual,
                "ctx_ram_unusualness": ram_unusual,
                "ctx_storage_unusualness": storage_unusual,
            },
            dtype=float,
        )

    def _query_conditioned_context_scores(
        self,
        query_pressure: pd.Series,
        mean_abs: pd.Series,
        sum_abs_delta: pd.Series,
    ) -> pd.Series:
        ctx = self._derive_context_scores_for_interaction(
            mean_abs=mean_abs,
            sum_abs_delta=sum_abs_delta,
        )

        def qp(name: str) -> float:
            return float(query_pressure.get(name, 0.0))

        def cs(name: str) -> float:
            return float(ctx.get(name, 0.0))

        return pd.Series(
            {
                "qctx_cpu_pressure_x_cpu_score":
                    qp("qp_total_cpu") * cs("ctx_cpu_score"),

                "qctx_cpu_pressure_x_cpu_unusualness":
                    qp("qp_total_cpu") * cs("ctx_cpu_unusualness"),

                "qctx_memory_pressure_x_ram_score":
                    qp("qp_total_memory") * cs("ctx_ram_score"),

                "qctx_memory_pressure_x_ram_unusualness":
                    qp("qp_total_memory") * cs("ctx_ram_unusualness"),

                "qctx_scan_pressure_x_storage_iops":
                    qp("qp_scan_pressure") * cs("ctx_storage_iops_score"),

                "qctx_scan_pressure_x_storage_bw":
                    qp("qp_scan_pressure") * cs("ctx_storage_bw_score"),

                "qctx_scan_pressure_x_storage_latency_risk":
                    qp("qp_scan_pressure") * cs("ctx_storage_latency_risk"),

                "qctx_exchange_pressure_x_storage_latency_risk":
                    qp("qp_exchange_pressure") * cs("ctx_storage_latency_risk"),

                "qctx_exchange_pressure_x_storage_unusualness":
                    qp("qp_exchange_pressure") * cs("ctx_storage_unusualness"),

                "qctx_join_pressure_x_ram_score":
                    qp("qp_join_pressure") * cs("ctx_ram_score"),

                "qctx_join_pressure_x_ram_unusualness":
                    qp("qp_join_pressure") * cs("ctx_ram_unusualness"),

                "qctx_sort_pressure_x_cpu_score":
                    qp("qp_sort_pressure") * cs("ctx_cpu_score"),

                "qctx_aggregate_pressure_x_cpu_score":
                    qp("qp_aggregate_pressure") * cs("ctx_cpu_score"),

            },
            dtype=float,
        )

    # -------------------------------------------------------------------------
    # Public API expected by embedding.py
    # -------------------------------------------------------------------------

    def encode_profile_as_series(
        self,
        profile_df: pd.DataFrame,
        plan: Dict[str, Any],
    ) -> pd.Series:
        """
        Encode one query-run profile and its corresponding query plan as a
        labelled feature vector.
        """
        context_abs = self._profile_to_group_relative_context_abs(profile_df)

        mean_abs = self._mean_pool_context_abs(context_abs)
        sum_delta = self._sum_pool_context_delta(context_abs)
        sum_abs_delta = self._sum_pool_abs_context_delta(context_abs)

        global_scores = self._global_deviation_scores(
            mean_abs=mean_abs,
            sum_delta=sum_delta,
            sum_abs_delta=sum_abs_delta,
        )

        query_pressure = transform_query_pressure(
            plan,
            self.pressure_ref_,
        )

        qctx_scores = self._query_conditioned_context_scores(
            query_pressure=query_pressure,
            mean_abs=mean_abs,
            sum_abs_delta=sum_abs_delta,
        )

        parts = []

        if self.include_abs:
            parts.append(mean_abs)
        
        if self.include_delta:
            if self.include_sum_delta:
                parts.append(sum_delta)
        
            parts.extend(
                [
                    sum_abs_delta,
                    global_scores,
                ]
            )
        
        if self.include_query_context:
            parts.append(qctx_scores)
        
        if not parts:
            raise ValueError(
                "LakehouseContextEncoder produced no features. "
                "At least one of include_abs, include_delta, or "
                "include_query_context must be True."
            )

        s = pd.concat(parts)
        s = s.replace([np.inf, -np.inf], np.nan).fillna(0.0)

        if self.feature_names_ is not None:
            s = s.reindex(self.feature_names_).fillna(0.0)

        return s

    def encode_profile(
        self,
        profile_df: pd.DataFrame,
        plan: Dict[str, Any],
    ) -> np.ndarray:
        """
        Return the context embedding as a numpy vector.
        """
        return self.encode_profile_as_series(
            profile_df=profile_df,
            plan=plan,
        ).to_numpy(dtype=float)

    def dim(self) -> int:
        if self.feature_names_ is None:
            raise ValueError("feature_names_ has not been inferred.")
        return len(self.feature_names_)

    def feature_names(self) -> List[str]:
        if self.feature_names_ is None:
            raise ValueError("feature_names_ has not been inferred.")
        return list(self.feature_names_)


# -----------------------------------------------------------------------------
# Local helper used during fitting
# -----------------------------------------------------------------------------

def _query_name_from_profile_df(df: pd.DataFrame) -> str | None:
    """
    Extract query_name from a profile DataFrame.

    Kept local so this encoder can live independently from embedding.py.
    """
    query_name = getattr(df, "attrs", {}).get("query_name")

    if query_name is None and "query_name" in df.columns:
        vals = df["query_name"].dropna()
        if len(vals) > 0:
            query_name = str(vals.iloc[0])

    return None if query_name is None else str(query_name)