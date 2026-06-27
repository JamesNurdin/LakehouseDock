from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple, Sequence, Protocol

import math

import gurobipy as gp
from gurobipy import GRB, Constr
import numpy as np

from carbon_scheduling.src.carbon import CarbonProfile
from carbon_scheduling.src.structs import RunningJob, QuerySpec, Plan, PowerModel, Logger
from carbon_scheduling.src.penalty import Penalty
from carbon_scheduling.src.objective import ObjectiveFunction
from carbon_scheduling.src.filter import QueryFilterPipeline, QueryFilterContext



@dataclass
class AbsoluteModelState:
    """Internal state for the persistent (absolute-time) MILP."""
    cp_id: int
    T: int
    K: int
    start_abs: List[int]                 # k -> absolute start slot
    qids: List[str]                      # stable ordering
    pending_by_qid: Dict[str, QuerySpec] # qid -> QuerySpec used to compute objective penalties

    # Capacity Constraints
    cpu_cap: List[Constr]
    ram_cap: List[Constr]

    # planning values (what MILP assumes for not-yet-started jobs)
    dur: Dict[str, int]
    cpu: Dict[str, float]
    ram: Dict[str, float]

    # model objects
    model: gp.Model
    x: Dict[Tuple[str, int], gp.Var]     # (qid,k) -> binary var
    valid_ks: Dict[str, List[int]]       # qid -> feasible k list

    # simple cache
    penalties_bound: List[Penalty]
    base_carbon: Dict[Tuple[str, int], float]  # (qid,k) -> carbon-only cost

    # bookkeeping for incremental updates
    fixed_qids: set                      # qids that have been fixed to a chosen k
    disabled_past_until: int             # all k with start_abs[k] < this are disabled


class OptimiserProtocol(Protocol):
    running: Dict[str, RunningJob]
    completed: set[str]
    power_model: PowerModel

    def build_model(
        self,
        *,
        cp: CarbonProfile,
        specs: List[QuerySpec],
        use_true_for_planning: bool = False,
    ) -> None: ...

    def update_model(self, *, now_slot: int) -> None: ...
    def reoptimize(self, *, now_slot: int) -> Plan: ...

    def start_jobs_from_plan(
        self,
        *,
        now_slot: int,
        plan: Plan,
        pending: Dict[str, QuerySpec],
        use_true_for_execution: bool = True,
    ) -> List[RunningJob]: ...

    def mark_completed(self, *, qid: str, finished_slot: int) -> None: ...

    def reset(self) -> None: ...
    
    def planned_durations(self) -> Dict[str, int]: ...

    def planned_resources(self) -> tuple[Dict[str, float], Dict[str, float]]: ...
        

class OptimiserMILP:
    """
    Absolute-time, persistent MILP scheduler updated incrementally between DES events.

    Correct handling of DES "actual execution state":

    - Not-yet-started jobs: MILP uses planned/predicted (dur/cpu/ram stored in state)
    - Started jobs: MILP variables for those jobs are FIXED (x=1 at chosen start),
      so their PLANNED resource usage is already included on the LHS of capacity constraints.
    - Therefore, when incorporating ACTUAL execution usage/duration, we must update RHS by
      the DELTA: (actual usage interval) - (planned usage interval). This avoids double counting.
    """

    def __init__(
        self,
        *,
        cpu_max: float,                                  # Total CPU capacity available in each scheduling slot
        ram_max: float,                                  # Total RAM capacity available in each scheduling slot
        query_filter_pipeline: Optional[QueryFilterPipeline] = None,
        objective: Optional[ObjectiveFunction] = None,   # Combined optimisation objective used to score candidate schedules
        penalties: Optional[Sequence[Penalty]] = None,   # Extra penalty terms added to the objective alongside carbon cost
        power_model: Optional[PowerModel] = None,        # Converts resource usage estimates into power draw for carbon calculations
        step_slots: int = 1,                             # Grid granularity for allowable query start times
        horizon_slots: Optional[int] = None,             # Planning horizon in slots; if None, use the full carbon-intensity horizon
        allow_idle: bool = True,                         # Allows the optimiser to leave resources idle when that gives a better schedule
        time_limit_s: float = 2.0,                       # Per-solve wall-clock time limit for the MILP solver
        mip_gap: Optional[float] = None,                 # Acceptable relative optimality gap for terminating MILP search early
        threads: Optional[int] = None,                   # Solver parallelism; if unset, use Gurobi's default thread selection
        verbose: bool = False,                           # Enables detailed logging and debugging information when True
        logger: Logger = Logger(False),
        seed: int = 42,
    ):
        self.cpu_max = float(cpu_max)
        self.ram_max = float(ram_max)
        
        self.penalties = penalties or []
        self.objective = objective or ObjectiveFunction()

        self.step_slots = int(max(1, step_slots))
        self.horizon_slots = None if horizon_slots is None else int(max(1, horizon_slots))
        self.allow_idle = bool(allow_idle)

        self.time_limit_s = float(time_limit_s)
        self.mip_gap = mip_gap
        self.seed = seed
        self.threads = threads
        self.verbose = verbose
        self.logger = logger

        self.query_filter_pipeline = query_filter_pipeline

        # DES state
        self.running: Dict[str, RunningJob] = {}
        self.completed: set[str] = set()
        self.started: Dict[str, RunningJob] = {}

        # Scheduler state
        self._last_start_slot: Dict[str, int] = {}

        # persistent Gurobi env
        self.env = gp.Env(empty=True)
        if not self.verbose:
            self.env.setParam("OutputFlag", 0)
        self.env.start()

        # persistent model state (built once)
        self._state: Optional[AbsoluteModelState] = None

        # Power & carbon modelling
        self.power_model = power_model or PowerModel(max_cpu=self.cpu_max, max_ram=self.ram_max)
        self._cp: Optional[CarbonProfile] = None

    # -----------------------------
    # Utility: delta capacity profile for started jobs (actual - planned)
    # -----------------------------
    def _capacity_delta_profile_abs(self, T: int) -> Tuple[np.ndarray, np.ndarray]:
        """
        Returns cpu_delta[t], ram_delta[t] for started jobs:
          delta[t] = (sum actual usage at t) - (sum planned usage at t)

        Why:
          - started jobs are FIXED in MILP, so planned usage is already on LHS
          - we want reality to reflect ACTUAL usage/duration
          - so we shift RHS by the delta, avoiding double counting.
        """
        cpu_delta = np.zeros(T, dtype=float)
        ram_delta = np.zeros(T, dtype=float)

        for r in self.started.values():
            s = int(max(0, r.start_slot))

            # planned interval already counted on LHS via fixed x-vars
            p_end = int(min(T, r.planned_end_slot))
            if p_end > s:
                cpu_delta[s:p_end] -= float(r.planned_cpu)
                ram_delta[s:p_end] -= float(r.planned_ram)

            # actual interval should be enforced in reality
            a_end = int(min(T, r.actual_end_slot))
            if a_end > s:
                cpu_delta[s:a_end] += float(r.actual_cpu)
                ram_delta[s:a_end] += float(r.actual_ram)

        return cpu_delta, ram_delta

    # -----------------------------
    # Build the model once
    # -----------------------------
    def build_model(
        self,
        *,
        cp: CarbonProfile,
        specs: List[QuerySpec],
        use_true_for_planning: bool = False,
    ) -> None:

        self.logger.log(f"Building Model")
        
        # Guardrails
        if self._state is not None:
            return
        self._cp = cp

        
        # Set planning horizon and grid
        T_end = int(len(cp.ci))
        if T_end <= 0:
            raise ValueError("CarbonProfile has empty CI horizon")
        T = T_end if self.horizon_slots is None else min(T_end, int(self.horizon_slots))
        K = int(math.floor((T - 1) / self.step_slots) + 1)
        start_abs = [k * self.step_slots for k in range(K)]

        
        # Bind penalties to the carbon profile (precompute constants)
        penalties_bound = [p.bind(cp) for p in (self.penalties or [])]


        # Build the parameters per query (dur/cpu/ram)
        dur: Dict[str, int] = {}
        cpu: Dict[str, float] = {}
        ram: Dict[str, float] = {}
        pending_by_qid: Dict[str, QuerySpec] = {q.qid: q for q in specs}
        qids = list(pending_by_qid.keys())
        for q in specs:
            if use_true_for_planning:
                d = int(max(1, round(float(q.dur_mean_slots_true))))
                c = float(q.cpu_mean_true)
                r = float(q.ram_mean_true)
            else:
                d = int(max(1, round(float(q.dur_mean_slots_pred))))
                c = float(q.cpu_mean_pred)
                r = float(q.ram_mean_pred)

            c = float(min(self.cpu_max, max(1.0, math.ceil(c))))
            r = float(min(self.ram_max, max(1.0, math.ceil(r))))
            
            dur[q.qid] = d
            cpu[q.qid] = c
            ram[q.qid] = r

        # Build power usage for queries
        pkw_by_qid: Dict[str, float] = {}
        for qid in qids:
            c = cpu[qid]   # planned cpu (pred or true depending on use_true_for_planning)
            r = ram[qid]   # planned ram
            pkw_by_qid[qid] = float(self.power_model.power_kw(c, r))

        # Initalise the Gurobi model + solver settings
        m = gp.Model("absolute_resource_mip", env=self.env)
        m.ModelSense = GRB.MINIMIZE
        m.Params.TimeLimit = float(self.time_limit_s)
        m.Params.Presolve = 1
        m.Params.PrePasses = 1
        m.Params.Aggregate = 0
        m.Params.PreSparsify = 1
        m.Params.MIPFocus = 1
        m.Params.Heuristics = 0.5
        m.Params.Cuts = 1
        if self.seed is not None:
            m.Params.Seed = int(self.seed)   
        if self.mip_gap is not None:
            m.Params.MIPGap = float(self.mip_gap)
        if self.threads is not None:
            m.Params.Threads = int(self.threads)

        # Load CP constants
        ci_prefix = cp.ci_prefix
        dt = float(cp.dt_hours)

        # Decide feasible candidate start indices per query
        x: Dict[Tuple[str, int], gp.Var] = {}
        valid_ks: Dict[str, List[int]] = {qid: [] for qid in qids}
        for qid in qids:
            d = dur[qid]
            k_max = (T - d) // self.step_slots
            if k_max < 0:
                raise RuntimeError(f"Query {qid} has no feasible start within T={T} slots")
            valid_ks[qid] = list(range(int(k_max) + 1))

        # Apply union-based candidate filtering
        if self.query_filter_pipeline is not None:
            self.logger.log(f"Filtering query start times")
            filter_ctx = QueryFilterContext(
                valid_ks=valid_ks,
                start_abs=start_abs,
                pending_by_qid=pending_by_qid,
                dur=dur,
                cpu=cpu,
                ram=ram,
                pkw_by_qid=pkw_by_qid,
                cp=cp,
                penalties_bound=penalties_bound,
                objective=self.objective,
                now_slot=0,
            )
            valid_ks = self.query_filter_pipeline.filter(filter_ctx)
        
        
        # Create decision variables x[(qid,k)] ∈ {0,1}
        self.logger.log(f"Creating decision variables")
        for qid in qids:
            if not valid_ks[qid]:
                raise RuntimeError(f"Query {qid} has no candidate starts after filtering.")
            for k in valid_ks[qid]:
                x[(qid, k)] = m.addVar(vtype=GRB.BINARY, name=f"x[{qid},{k}]")
        m.update()

        
        # Build Start-once constraints
        self.logger.log(f"Creating start-once constraints")
        for qid in qids:
            m.addConstr(
                gp.quicksum(x[(qid, k)] for k in valid_ks[qid]) == 1,
                name=f"start_once[{qid}]",
            )

        # Build resource capacity constraints
        self.logger.log(f"Creating capacity constraints")
        cpu_exprs = [gp.LinExpr() for _ in range(T)]
        ram_exprs = [gp.LinExpr() for _ in range(T)]
        for qid in qids:
            d = dur[qid]
            c = cpu[qid]
            r = ram[qid]
            for k in valid_ks[qid]:
                s = start_abs[k]
                var = x[(qid, k)]
                for t in range(s, s + d):
                    cpu_exprs[t].addTerms(c, var)
                    ram_exprs[t].addTerms(r, var)

        cpu_constrs: List[Constr] = []
        ram_constrs: List[Constr] = []
        for t in range(T):
            cpu_constrs.append(m.addConstr(cpu_exprs[t] <= self.cpu_max, name=f"cpu_cap[{t}]"))
            ram_constrs.append(m.addConstr(ram_exprs[t] <= self.ram_max, name=f"ram_cap[{t}]"))

        
        # Compute base carbon and pre-set penalties for recomputation
        self.logger.log(f"Computing base carbon emissions")
        base_carbon: Dict[Tuple[str, int], float] = {}
        for qid in qids:
            d = dur[qid]
            pkw = pkw_by_qid[qid]
            for k in valid_ks[qid]:
                s = start_abs[k]
                ci_sum = float(ci_prefix[s + d] - ci_prefix[s])
                carbon = float(ci_sum * pkw * dt)
                base_carbon[(qid, k)] = carbon
                x[(qid, k)].Obj = 0.0 # Set for 0 this will be updated after state has been declared
        m.update()

        # Freeze model (Update state)
        self._state = AbsoluteModelState(
            cp_id=id(cp),
            T=T,
            K=K,
            start_abs=start_abs,
            qids=qids,
            pending_by_qid=pending_by_qid,
            dur=dur,
            cpu=cpu,
            ram=ram,
            cpu_cap=cpu_constrs,
            ram_cap=ram_constrs,
            base_carbon=base_carbon,
            model=m,
            x=x,
            valid_ks=valid_ks,
            penalties_bound=penalties_bound,
            fixed_qids=set(),
            disabled_past_until=0,
        )
        
        # Compute objective weighting scales
        self.logger.log(f"Initalising policy scales")
        self._init_penalty_scales()
        
        vals = list(base_carbon.values())
        if vals:
            vals.sort()
            self.objective.carbon_scale = max(self.objective.eps, vals[len(vals)//2])
        else:
            self.objective.carbon_scale = 1.0
        
        # Ensure initial model consistent with current DES reality
        self.logger.log(f"Calculating objectives")
        self.calculate_objective()
        self._update_capacity_rhs_from_running()
        self.disable_past_starts(now_slot=0)        

    # -----------------------------
    # Incremental updates
    # -----------------------------

    def _init_penalty_scales(self) -> None:
        st = self._require_state()
        if self._cp is None:
            raise RuntimeError("CarbonProfile not set.")
        cp = self._cp
    
        if not st.penalties_bound:
            self.objective.penalty_scales = {}
            return
    
        key_fn = self.objective.penalty_key_fn
        eps = float(self.objective.eps)
    
        def robust_scale(vals: list[float]) -> float:
            pos = [v for v in vals if v > 0.0]
            if pos:
                pos.sort()
                return max(eps, float(pos[len(pos)//2]))  # median of positives
            if vals:
                vs = sorted(vals)
                idx = int(0.75 * (len(vs) - 1)) if len(vs) > 1 else 0
                return max(eps, float(vs[idx]))
            return 1.0
    
        vals_by_key: dict[str, list[float]] = {}
    
        for qid in st.qids:
            q = st.pending_by_qid[qid]
            d = int(st.dur[qid])
            for k in st.valid_ks[qid]:
                s = int(st.start_abs[k])
                for p in st.penalties_bound:
                    key = key_fn(p)
                    v = float(p.coeff(q=q, start_abs=s, dur_slots=d, cp=cp))
                    vals_by_key.setdefault(key, []).append(v)
    
        self.objective.penalty_scales = {key: robust_scale(vals) for key, vals in vals_by_key.items()}

    def debug_objective_state(self, *, now_slot: int, max_q: int = 3, max_k: int = 3) -> None:
        """
        Print objective scaling, penalty weights, and sample objective terms.
        Call after calculate_objective().
        """
        st = self._require_state()
        now_slot = int(now_slot)
    
        print("\n=== OBJECTIVE STATE ===")
        print("now_slot:", now_slot)
        print("w_carbon:", self.objective.w_carbon)
        print("w_penalties:", self.objective.w_penalties)
        print("carbon_scale:", self.objective.carbon_scale)
    
        # Penalty scales + weights
        print("\nPenalty scales and weights:")
        if not st.penalties_bound:
            print("  (no penalties)")
        else:
            for p in st.penalties_bound:
                key = self.objective.penalty_key_fn(p)
                scale = self.objective.penalty_scales.get(key, self.objective.default_penalty_scale)
                print(f"  {key:30s} weight={p.weight:8.4f}  scale={scale:12.6f}")
    
        # Sample decomposition
        print("\nSample objective terms:")
        shown_q = 0
        for qid in st.qids:
            if qid in st.fixed_qids:
                continue
            ks = st.valid_ks.get(qid, [])
            if not ks:
                continue
    
            q = st.pending_by_qid[qid]
            d = int(st.dur[qid])
    
            print(f"\n  qid={qid}")
            shown_k = 0
    
            for k in ks:
                if st.x[(qid, k)].UB < 0.5:
                    continue
                if shown_k >= max_k:
                    break
    
                s = int(st.start_abs[k])
                base_c = float(st.base_carbon[(qid, k)])
    
                # carbon term
                cs = max(self.objective.eps, float(self.objective.carbon_scale or 1.0))
                carbon_term = self.objective.w_carbon * (base_c / cs)
    
                # penalties
                pen_total = 0.0
                pen_parts = []
                for p in st.penalties_bound:
                    key = self.objective.penalty_key_fn(p)
                    scale = max(self.objective.eps,
                                float(self.objective.penalty_scales.get(key, self.objective.default_penalty_scale)))
                    val = float(p.coeff(
                        q=q, start_abs=s, dur_slots=d, now_slot=now_slot, cp=self._cp
                    ))
                    contrib = self.objective.w_penalties * p.weight * (val / scale)
                    pen_total += contrib
                    pen_parts.append((key, val, scale, contrib))
    
                obj = carbon_term + pen_total
    
                print(f"    k={k:4d} start={s:6d}  carbon={carbon_term:10.6f}  penalties={pen_total:10.6f}  Obj={obj:10.6f}")
    
                for key, val, scale, contrib in pen_parts:
                    print(f"       - {key:26s} raw={val:10.6f}  scale={scale:10.6f}  contrib={contrib:10.6f}")
    
                shown_k += 1
    
            shown_q += 1
            if shown_q >= max_q:
                break
    
        print("=== END OBJECTIVE STATE ===\n")
    
    def _update_capacity_rhs_from_running(self) -> None:
        st = self._require_state()

        # DELTA (actual - planned) for started jobs
        cpu_delta, ram_delta = self._capacity_delta_profile_abs(st.T)

        for t in range(st.T):
            st.cpu_cap[t].RHS = self.cpu_max - float(cpu_delta[t])
            st.ram_cap[t].RHS = self.ram_max - float(ram_delta[t])

        st.model.update()

    def calculate_objective(self) -> None:
        st = self._require_state()
    
        if self._cp is None:
            raise RuntimeError("CarbonProfile not set. build_model() must be called first.")
        cp = self._cp
    
        # If no penalties, keep objective carbon-only (fast path)
        if not st.penalties_bound:
            cs = float(self.objective.carbon_scale) if self.objective.carbon_scale else 1.0
            cs = max(self.objective.eps, cs)
    
            for qid in st.qids:
                if qid in st.fixed_qids:
                    continue
                for k in st.valid_ks[qid]:
                    base_c = float(st.base_carbon[(qid, k)])
                    st.x[(qid, k)].Obj = float(self.objective.w_carbon) * (base_c / cs)
    
            st.model.update()
            return
            
        # PASS 1: compute coeffs ONCE, cache per (qid,k), and collect per-penalty values
        pen_cache: dict[tuple[str, int], dict[str, float]] = {}
        for qid in st.qids:
            if qid in st.fixed_qids:
                continue
            q = st.pending_by_qid[qid]
            d = int(st.dur[qid])
        
            for k in st.valid_ks[qid]:
                s = int(st.start_abs[k])
                per: dict[str, float] = {}
        
                for p in st.penalties_bound:
                    key = self.objective.penalty_key_fn(p)
                    v = float(p.coeff(q=q, start_abs=s, dur_slots=d, cp=cp))
                    per[key] = v
        
                pen_cache[(qid, k)] = per
    
    
        # PASS 2: set Obj using cached values (no coeff calls)
        for qid in st.qids:
            if qid in st.fixed_qids:
                continue
            for k in st.valid_ks[qid]:
                st.x[(qid, k)].Obj = self.objective.cost(
                    base_carbon=float(st.base_carbon[(qid, k)]),
                    penalties_bound=st.penalties_bound,
                    cached_penalty_vals=pen_cache[(qid, k)],
                )
    
        st.model.update()

    
    def disable_past_starts(self, *, now_slot: int) -> None:
        st = self._require_state()
        if now_slot <= st.disabled_past_until:
            return

        cutoff = int(now_slot)
        st.disabled_past_until = cutoff

        for qid in st.qids:
            if qid in st.fixed_qids:
                continue
            for k in st.valid_ks[qid]:
                if st.start_abs[k] < cutoff:
                    st.x[(qid, k)].UB = 0.0

        st.model.update()

    def fix_started(self, *, qid: str, start_slot: int) -> None:
        st = self._require_state()
        if qid in st.fixed_qids:
            return

        if start_slot % self.step_slots != 0:
            raise RuntimeError(
                f"Cannot fix {qid}: start_slot={start_slot} is off-grid for step_slots={self.step_slots}."
            )
        k = int(start_slot // self.step_slots)

        if k not in st.valid_ks.get(qid, []):
            raise RuntimeError(
                f"Cannot fix {qid} at k={k} (not in valid_ks)."
            )

        for kk in st.valid_ks[qid]:
            var = st.x[(qid, kk)]
            if kk == k:
                var.LB = 1.0
                var.UB = 1.0
            else:
                var.UB = 0.0

        st.fixed_qids.add(qid)
        st.model.update()

    def optimize(self) -> None:
        st = self._require_state()
        st.model.optimize()

        if st.model.SolCount <= 0:
            if st.model.Status == GRB.TIME_LIMIT:
                raise RuntimeError("Time limit reached before finding a feasible schedule.")
            raise RuntimeError(f"No feasible solution (status={st.model.Status}).")

    def get_plan(self, *, now_slot: int) -> Plan:
        st = self._require_state()

        start_slot: Dict[str, int] = {}
        for qid in st.qids:
            best_k = None
            best_val = -1.0
            for k in st.valid_ks[qid]:
                v = st.x[(qid, k)].X
                if v > best_val:
                    best_val = v
                    best_k = k
            if best_k is None:
                continue
            start_slot[qid] = int(st.start_abs[best_k])
            
        self._last_start_slot = dict(start_slot)
        return Plan(start_slot=start_slot)

    # -----------------------------
    # DES interfacing
    # -----------------------------
    def start_jobs_from_plan(
        self,
        *,
        now_slot: int,
        plan: Plan,
        pending: Dict[str, QuerySpec],
        use_true_for_execution: bool = True,
    ) -> List[RunningJob]:
        now_slot = int(now_slot)

        # Actual free resources at now (DES reality)
        cpu_used = sum(
            r.actual_cpu
            for r in self.running.values()
            if r.start_slot <= now_slot < r.actual_end_slot
        )
        ram_used = sum(
            r.actual_ram
            for r in self.running.values()
            if r.start_slot <= now_slot < r.actual_end_slot
        )
        cpu_free = self.cpu_max - cpu_used
        ram_free = self.ram_max - ram_used

        buckets: Dict[int, List[str]] = {}
        for qid, s in plan.start_slot.items():
            s = int(s)
            if s % self.step_slots != 0:
                raise RuntimeError(f"Plan produced off-grid start s={s} (step_slots={self.step_slots}).")
            if qid in pending and s == now_slot:
                buckets.setdefault(s, []).append(qid)

        started: List[RunningJob] = []

        for s in sorted(buckets.keys()):
            qids = sorted(buckets[s])
            for qid in qids:
                q = pending[qid]

                # planned (what MILP assumed)
                st = self._require_state()

                # planned MUST match what the MILP used (st.dur/st.cpu/st.ram),
                # otherwise delta RHS adjustment is wrong and you can go infeasible.
                d_plan = int(st.dur[qid])
                cpu_plan = float(st.cpu[qid])
                ram_plan = float(st.ram[qid])


                # actual (DES truth)
                if use_true_for_execution:
                    d_act = int(max(1, round(float(q.dur_mean_slots_true))))
                    cpu_act = float(min(self.cpu_max, max(1.0, math.ceil(float(q.cpu_mean_true)))))
                    ram_act = float(min(self.ram_max, max(1.0, math.ceil(float(q.ram_mean_true)))))
                else:
                    d_act, cpu_act, ram_act = d_plan, cpu_plan, ram_plan

                if cpu_act <= cpu_free + 1e-9 and ram_act <= ram_free + 1e-9:
                    rj = RunningJob(
                        qid=qid,
                        start_slot=int(s),

                        planned_end_slot=int(s) + d_plan,
                        planned_cpu=cpu_plan,
                        planned_ram=ram_plan,

                        actual_end_slot=int(s) + d_act,
                        actual_cpu=cpu_act,
                        actual_ram=ram_act,
                    )

                    self.running[qid] = rj
                    self.started[qid] = rj  # <-- CRITICAL: keep for delta RHS updates
                    started.append(rj)

                    cpu_free -= cpu_act
                    ram_free -= ram_act

                    # Commit decision into MILP
                    self.fix_started(qid=qid, start_slot=int(s))

        return started

    def mark_completed(self, *, qid: str, finished_slot: int) -> None:
        self.completed.add(qid)
        self.running.pop(qid, None)
      
    def planned_durations(self) -> Dict[str, int]:
        st = self._require_state()
        return {qid: int(st.dur[qid]) for qid in st.qids}

    def planned_resources(self) -> tuple[Dict[str, float], Dict[str, float]]:
        st = self._require_state()
        planned_cpu = {qid: float(st.cpu[qid]) for qid in st.qids}
        planned_ram = {qid: float(st.ram[qid]) for qid in st.qids}
        return planned_cpu, planned_ram

    def _apply_warm_start(self) -> None:
        st = self._require_state()
    
        for qid in st.qids:
            chosen_s = self._last_start_slot.get(qid, None)
    
            if chosen_s is not None and chosen_s % self.step_slots == 0:
                chosen_k = chosen_s // self.step_slots
            else:
                chosen_k = None
    
            for k in st.valid_ks[qid]:
                var = st.x[(qid, k)]
                var.Start = GRB.UNDEFINED
    
                if qid in st.fixed_qids:
                    var.Start = 1.0 if var.LB > 0.5 else 0.0
                elif chosen_k is not None and chosen_k in st.valid_ks[qid]:
                    if var.UB > 0.5:
                        var.Start = 1.0 if k == chosen_k else 0.0
    
        st.model.update()

    def reset(self) -> None:
        # Clear DES/runtime state
        self.running.clear()
        self.completed.clear()
        self.started.clear()
    
        # Drop built model state so build_model(...) can create a fresh one
        if self._state is not None:
            try:
                self._state.model.dispose()
            except Exception:
                pass
    
        self._state = None
        self._cp = None
        
        self._last_start_slot = {}
        self.objective.penalty_scales = {}
        self.objective.carbon_scale = 1.0

    def update_model(self, *, now_slot: int) -> None:
        self.disable_past_starts(now_slot=now_slot)
        self._update_capacity_rhs_from_running()

    def reoptimize(self, *, now_slot: int) -> Plan:
        self.update_model(now_slot=now_slot)
        self._apply_warm_start()
        if self.verbose:
            self.debug_objective_state(now_slot=now_slot)
        self.optimize()
        return self.get_plan(now_slot=now_slot)

    # -----------------------------
    # Helpers
    # -----------------------------
    def _require_state(self) -> AbsoluteModelState:
        if self._state is None:
            raise RuntimeError("Absolute model not built. Call build_model(cp=..., specs=...).")
        return self._state




class LetsWaitAwhileScheduler:
    """
    Non-interrupting 'Let's Wait Awhile' style scheduler.

    Policy idea:
      For each not-yet-started query, choose the future start slot whose
      duration-length window has the lowest mean carbon intensity.

    Notes:
    - This ports the non-interrupting AdHocStrategy 
    - It keeps DES execution semantics: once started, a query runs contiguously until completion.
    """

    def __init__(
        self,
        *,
        cpu_max: float,
        ram_max: float,
        power_model: Optional[PowerModel] = None,
        step_slots: int = 1,
        forecast_horizon_slots: Optional[int] = None,
        commit_window_slots: int = 0,
        allow_idle: bool = True,
        sort_mode: str = "priority_then_duration",
    ):
        self.cpu_max = float(cpu_max)
        self.ram_max = float(ram_max)

        self.step_slots = int(max(1, step_slots))
        self.forecast_horizon_slots = (
            None if forecast_horizon_slots is None else int(max(1, forecast_horizon_slots))
        )
        self.commit_window_slots = int(max(0, commit_window_slots))
        self.allow_idle = bool(allow_idle)
        self.sort_mode = str(sort_mode)

        self.power_model = power_model or PowerModel(
            max_cpu=self.cpu_max,
            max_ram=self.ram_max,
        )

        # DES state required by your experiment protocol
        self.running: Dict[str, RunningJob] = {}
        self.completed: set[str] = set()
        self.started: Dict[str, RunningJob] = {}

        # built-once planning state
        self._cp: Optional[CarbonProfile] = None
        self._specs_by_qid: Dict[str, QuerySpec] = {}
        self._planned_dur: Dict[str, int] = {}
        self._planned_cpu: Dict[str, float] = {}
        self._planned_ram: Dict[str, float] = {}

    # -----------------------------
    # lifecycle
    # -----------------------------
    def reset(self) -> None:
        self.running.clear()
        self.completed.clear()
        self.started.clear()

        self._cp = None
        self._specs_by_qid = {}
        self._planned_dur = {}
        self._planned_cpu = {}
        self._planned_ram = {}

    def build_model(
        self,
        *,
        cp: CarbonProfile,
        specs: List[QuerySpec],
        use_true_for_planning: bool = False,
    ) -> None:
        # mirror your MILP "build once" semantics
        if self._cp is not None:
            return

        if len(cp.ci) <= 0:
            raise ValueError("CarbonProfile has empty CI horizon")

        self._cp = cp
        self._specs_by_qid = {q.qid: q for q in specs}

        for q in specs:
            if use_true_for_planning:
                d = int(max(1, round(float(q.dur_mean_slots_true))))
                c = float(q.cpu_mean_true)
                r = float(q.ram_mean_true)
            else:
                d = int(max(1, round(float(q.dur_mean_slots_pred))))
                c = float(q.cpu_mean_pred)
                r = float(q.ram_mean_pred)

            c = float(min(self.cpu_max, max(1.0, math.ceil(c))))
            r = float(min(self.ram_max, max(1.0, math.ceil(r))))

            self._planned_dur[q.qid] = d
            self._planned_cpu[q.qid] = c
            self._planned_ram[q.qid] = r

    def planned_durations(self) -> Dict[str, int]:
        return dict(self._planned_dur)

    def planned_resources(self) -> tuple[Dict[str, float], Dict[str, float]]:
        return dict(self._planned_cpu), dict(self._planned_ram)

    # -----------------------------
    # planning
    # -----------------------------
    def update_model(self, *, now_slot: int) -> None:
        # No persistent optimisation model to update for this scheduler.
        return

    def reoptimize(self, *, now_slot: int) -> Plan:
        cp = self._require_cp()
        now_slot = int(now_slot)
    
        # queries still to be scheduled by the planner
        pending_qids = [
            qid for qid in self._specs_by_qid
            if qid not in self.completed and qid not in self.started
        ]
    
        start_slot: Dict[str, int] = {}
    
        if not pending_qids:
            return Plan(start_slot=start_slot)
    
        qids_ordered = self._ordered_qids(pending_qids)
    
        for qid in qids_ordered:
            d = int(self._planned_dur[qid])
            best_s = self._best_start_for_query(
                qid=qid,
                now_slot=now_slot,
                dur_slots=d,
                cp=cp,
            )
            start_slot[qid] = int(best_s)
    
        return Plan(start_slot=start_slot)

    def _best_start_for_query(
        self,
        *,
        qid: str,
        now_slot: int,
        dur_slots: int,
        cp: CarbonProfile,
    ) -> int:
        """
        Choose start slot with minimum mean CI over [s, s+dur).
        This mirrors the non-interrupting AdHocStrategy idea.
        """
        T = int(len(cp.ci))
        dur_slots = int(max(1, dur_slots))

        latest_start_global = max(0, T - dur_slots)

        if self.forecast_horizon_slots is None:
            latest_start = latest_start_global
        else:
            latest_start = min(
                latest_start_global,
                int(now_slot + self.forecast_horizon_slots),
            )

        if latest_start < now_slot:
            return int(now_slot)

        candidates = range(int(now_slot), int(latest_start) + 1, self.step_slots)

        best_s = None
        best_mean_ci = None

        for s in candidates:
            mean_ci = self._mean_ci(cp=cp, s=int(s), d=dur_slots)

            if (
                best_mean_ci is None
                or mean_ci < best_mean_ci - 1e-12
                or (
                    abs(mean_ci - best_mean_ci) <= 1e-12
                    and int(s) < int(best_s)
                )
            ):
                best_mean_ci = float(mean_ci)
                best_s = int(s)

        return int(now_slot if best_s is None else best_s)

    def _ordered_qids(self, qids: List[str]) -> List[str]:
        if self.sort_mode == "duration":
            return sorted(qids, key=lambda qid: (self._planned_dur[qid], qid))

        if self.sort_mode == "priority":
            return sorted(qids, key=lambda qid: (self._specs_by_qid[qid].priority, qid))

        if self.sort_mode == "priority_then_duration":
            return sorted(
                qids,
                key=lambda qid: (
                    self._specs_by_qid[qid].priority,
                    self._planned_dur[qid],
                    qid,
                ),
            )

        return sorted(qids)

    # -----------------------------
    # DES execution
    # -----------------------------
    def start_jobs_from_plan(
        self,
        *,
        now_slot: int,
        plan: Plan,
        pending: Dict[str, QuerySpec],
        use_true_for_execution: bool = True,
    ) -> List[RunningJob]:
        now_slot = int(now_slot)
        commit_end = now_slot + int(self.commit_window_slots)

        cpu_used = sum(
            r.actual_cpu
            for r in self.running.values()
            if r.start_slot <= now_slot < r.actual_end_slot
        )
        ram_used = sum(
            r.actual_ram
            for r in self.running.values()
            if r.start_slot <= now_slot < r.actual_end_slot
        )

        cpu_free = self.cpu_max - cpu_used
        ram_free = self.ram_max - ram_used

        # Only queries planned to start now..commit_end can be launched
        buckets: Dict[int, List[str]] = {}
        for qid, s in plan.start_slot.items():
            s = int(s)
            if s % self.step_slots != 0:
                raise RuntimeError(
                    f"Plan produced off-grid start s={s} (step_slots={self.step_slots})."
                )
            if qid in pending and now_slot <= s <= commit_end:
                buckets.setdefault(s, []).append(qid)

        started: List[RunningJob] = []

        for s in sorted(buckets):
            for qid in sorted(buckets[s]):
                q = pending[qid]

                # planning-side values
                d_plan = int(self._planned_dur[qid])
                cpu_plan = float(self._planned_cpu[qid])
                ram_plan = float(self._planned_ram[qid])

                # execution-side truth
                if use_true_for_execution:
                    d_act = int(max(1, round(float(q.dur_mean_slots_true))))
                    cpu_act = float(min(self.cpu_max, max(1.0, math.ceil(float(q.cpu_mean_true)))))
                    ram_act = float(min(self.ram_max, max(1.0, math.ceil(float(q.ram_mean_true)))))
                else:
                    d_act = d_plan
                    cpu_act = cpu_plan
                    ram_act = ram_plan

                if cpu_act <= cpu_free + 1e-9 and ram_act <= ram_free + 1e-9:
                    rj = RunningJob(
                        qid=qid,
                        start_slot=int(s),

                        planned_end_slot=int(s) + d_plan,
                        planned_cpu=cpu_plan,
                        planned_ram=ram_plan,

                        actual_end_slot=int(s) + d_act,
                        actual_cpu=cpu_act,
                        actual_ram=ram_act,
                    )

                    self.running[qid] = rj
                    self.started[qid] = rj
                    started.append(rj)

                    cpu_free -= cpu_act
                    ram_free -= ram_act

        return started

    def mark_completed(self, *, qid: str, finished_slot: int) -> None:
        self.completed.add(qid)
        self.running.pop(qid, None)

    # -----------------------------
    # helpers
    # -----------------------------

    
    def _require_cp(self) -> CarbonProfile:
        if self._cp is None:
            raise RuntimeError("Scheduler not built. Call build_model(cp=..., specs=...).")
        return self._cp

    @staticmethod
    def _mean_ci(*, cp: CarbonProfile, s: int, d: int) -> float:
        s = int(max(0, s))
        e = int(min(len(cp.ci), s + max(1, d)))
        if e <= s:
            return float("inf")

        if hasattr(cp, "ci_prefix") and cp.ci_prefix is not None:
            return float((cp.ci_prefix[e] - cp.ci_prefix[s]) / float(e - s))

        return float(np.mean(cp.ci[s:e]))
