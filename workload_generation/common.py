"""
Shared infrastructure for the related-work baselines.

The design goal is *fairness*: every baseline should differ from QueryDock
only in its generation pipeline, so all the surrounding machinery
(schema loading, live DDL introspection, LLM client + retry/back-off,
EXPLAIN validation, cost profiling, and the on-disk workload layout) is
shared here and re-used from ``trino_stack`` wherever it already exists.

Two entry points build a :class:`BaselineContext`:

  * :func:`context_from_lakehouse` -- pass a live ``Lakehouse`` instance
    (exactly like ``lh.generate_workload(...)`` in the notebook).  Uses the
    Lakehouse's Trino host for validation / profiling / value sampling.

  * :func:`context_from_factories` -- pass raw ``conn_factory`` /
    ``client_factory`` callables for standalone use / testing.
"""

from __future__ import annotations

import json
import random
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Tuple

from workload_generation.query_generator import (  # re-use helpers
    load_schema,
    make_openai_client,
    warm_up_model,
    build_table_ddl_context,
    fetch_table_columns,
    fetch_table_columns_cached,
    build_relationship_graph,
    get_relevant_relationships,
    relationship_to_text,
    sanitize_sql,
    extract_schema_tables,
    call_with_retry,
)
from trino_stack.workload import ensure_dir, utc_now_stamp
from trino_stack.config import (
    MODEL_NAME,
    BASE_MODEL_URL,
    API_KEY_ENV,
    WORKLOAD_ROOT,
)

from workload_generation.sql_features import query_features, workload_metaheuristics


# ---------------------------------------------------------------------------
# Context
# ---------------------------------------------------------------------------

@dataclass
class BaselineContext:
    """Everything a baseline needs to talk to the lakehouse + the LLM."""

    schema_json: Dict[str, Any]
    trino_schema: str
    catalog: str
    conn_factory: Callable[[], Any]
    client_factory: Callable[[], Any]
    model_name: str = MODEL_NAME
    base_url: str = BASE_MODEL_URL
    temperature: float = 0.6
    reasoning: str = "medium"

    # shared thread-safe DDL cache (mirrors query_generator)
    ddl_cache: Dict[str, List[dict]] = field(default_factory=dict)
    ddl_cache_lock: "threading.Lock" = field(default_factory=threading.Lock)
    _thread_local: threading.local = field(default_factory=threading.local, repr=False)

    # ------------------------------------------------------------------
    # LLM
    # ------------------------------------------------------------------
    def client(self):
        """Thread-local OpenAI client (safe to call from worker threads)."""
        if not hasattr(self._thread_local, "client"):
            self._thread_local.client = self.client_factory()
        return self._thread_local.client

    def warm_up(self) -> None:
        warm_up_model(self.client_factory(), model_name=self.model_name)

    def responses_text(
        self,
        *,
        instructions: str,
        prompt: str,
        temperature: Optional[float] = None,
        reasoning: Optional[str] = None,
        json_schema: Optional[dict] = None,
    ) -> str:
        """
        Single plain-text (or structured-JSON) LLM call using the same
        ``client.responses.create`` surface + retry/back-off as QueryDock.
        Returns the raw ``output_text``.
        """
        client = self.client()
        text_arg = None
        if json_schema is not None:
            text_arg = {"format": {"type": "json_schema", **json_schema}}

        def _call():
            kwargs = dict(
                model=self.model_name,
                instructions=instructions,
                input=prompt,
                reasoning={"effort": reasoning or self.reasoning},
                temperature=self.temperature if temperature is None else temperature,
                store=False,
            )
            if text_arg is not None:
                kwargs["text"] = text_arg
            return client.responses.create(**kwargs)

        result = call_with_retry(_call)
        return result.output_text

    # ------------------------------------------------------------------
    # Schema / DDL context (re-uses QueryDock)
    # ------------------------------------------------------------------
    def schema_tables(self) -> List[str]:
        return extract_schema_tables(self.schema_json)

    def relationship_graph(self):
        return build_relationship_graph(self.schema_json)

    def ddl_for(self, tables: List[str]) -> str:
        return build_table_ddl_context(
            conn_factory=self.conn_factory,
            catalog=self.catalog,
            schema=self.trino_schema,
            tables=tables,
            ddl_cache=self.ddl_cache,
            ddl_cache_lock=self.ddl_cache_lock,
        )

    def full_ddl(self) -> str:
        return self.ddl_for(self.schema_tables())

    def columns_for(self, table: str) -> List[dict]:
        return fetch_table_columns_cached(
            conn_factory=self.conn_factory,
            catalog=self.catalog,
            schema=self.trino_schema,
            table=table,
            ddl_cache=self.ddl_cache,
            ddl_cache_lock=self.ddl_cache_lock,
        )

    def join_rules_text(self, tables: List[str]) -> List[str]:
        rels = get_relevant_relationships(self.schema_json, tables)
        return [relationship_to_text(r) for r in rels]

    def foreign_key_text(self, tables: Optional[List[str]] = None) -> str:
        tables = tables or self.schema_tables()
        rels = get_relevant_relationships(self.schema_json, tables)
        if not rels:
            return "-- no declared foreign-key relationships between these tables"
        return "\n".join(f"- {relationship_to_text(r)}" for r in rels)

    # ------------------------------------------------------------------
    # Validation / cost (live Trino)
    # ------------------------------------------------------------------
    def validate_explain(self, sql: str) -> Tuple[bool, Optional[str]]:
        """
        EXPLAIN-based syntactic/semantic validation -- the same signal used by
        ``Lakehouse.validate_query_explain`` (and by E2ETune / SQLBarber /
        SQLStorm in their own pipelines).  Returns ``(ok, error_message)``.
        """
        sql = sanitize_sql(sql)
        if not sql:
            return False, "empty query"
        conn = self.conn_factory()
        try:
            cur = conn.cursor()
            try:
                cur.execute(f"EXPLAIN {sql}")
                cur.fetchall()
                return True, None
            finally:
                cur.close()
        except Exception as e:  # TrinoUserError etc.
            return False, f"{type(e).__name__}: {e}"
        finally:
            try:
                conn.close()
            except Exception:
                pass

    def explain_cost(self, sql: str) -> Optional[Dict[str, float]]:
        """
        Estimated cost from ``EXPLAIN (FORMAT JSON)`` -- used by the SQLBarber
        cost-aware generator.  Returns ``{"output_rows", "cpu_cost", ...}`` or
        ``None`` if the plan can't be produced/parsed.
        """
        sql = sanitize_sql(sql)
        if not sql:
            return None
        conn = self.conn_factory()
        try:
            cur = conn.cursor()
            try:
                cur.execute(f"EXPLAIN (FORMAT JSON) {sql}")
                rows = cur.fetchall()
            finally:
                cur.close()
        except Exception:
            return None
        finally:
            try:
                conn.close()
            except Exception:
                pass

        if not rows:
            return None
        try:
            doc = json.loads(rows[0][0])
        except Exception:
            return None
        return _estimates_from_trino_plan(doc)

    def sample_column_values(
        self, table: str, column: str, *, limit: int = 20
    ) -> List[Any]:
        """
        Sample distinct values for a column (E2ETune's "Predicate Generation
        Aid").  Best-effort: returns ``[]`` on any error.
        """
        conn = self.conn_factory()
        try:
            cur = conn.cursor()
            try:
                cur.execute(
                    f"SELECT DISTINCT {column} FROM {self.catalog}."
                    f"{self.trino_schema}.{table} "
                    f"WHERE {column} IS NOT NULL LIMIT {int(limit)}"
                )
                return [r[0] for r in cur.fetchall()]
            finally:
                cur.close()
        except Exception:
            return []
        finally:
            try:
                conn.close()
            except Exception:
                pass

    def validate_batch(
        self, candidates: List[dict], *, workers: int = 4
    ) -> Tuple[List[dict], List[dict]]:
        """Parallel EXPLAIN validation of a list of ``{"sql": ...}`` dicts."""
        valid: List[dict] = []
        invalid: List[dict] = []

        def worker(cand):
            ok, err = self.validate_explain(cand.get("sql", ""))
            return cand, ok, err

        with ThreadPoolExecutor(max_workers=max(1, workers)) as ex:
            futs = [ex.submit(worker, c) for c in candidates]
            for fut in as_completed(futs):
                cand, ok, err = fut.result()
                if ok:
                    valid.append(cand)
                else:
                    cand = dict(cand)
                    cand["error"] = err
                    invalid.append(cand)
        return valid, invalid


def _estimates_from_trino_plan(doc: Any) -> Optional[Dict[str, float]]:
    """Pull the root output-row / cpu-cost estimates from a Trino JSON plan."""
    # Trino EXPLAIN (FORMAT JSON) is a nested dict with "estimates" lists.
    best = {"output_rows": None, "cpu_cost": None, "memory_cost": None,
            "network_cost": None}

    def visit(node):
        if isinstance(node, dict):
            ests = node.get("estimates")
            if isinstance(ests, list):
                for e in ests:
                    if not isinstance(e, dict):
                        continue
                    orc = e.get("outputRowCount")
                    if orc is not None and best["output_rows"] is None:
                        best["output_rows"] = _to_float(orc)
                    cpu = e.get("cpuCost")
                    if cpu is not None and best["cpu_cost"] is None:
                        best["cpu_cost"] = _to_float(cpu)
                    if e.get("memoryCost") is not None and best["memory_cost"] is None:
                        best["memory_cost"] = _to_float(e.get("memoryCost"))
                    if e.get("networkCost") is not None and best["network_cost"] is None:
                        best["network_cost"] = _to_float(e.get("networkCost"))
            for v in node.values():
                visit(v)
        elif isinstance(node, list):
            for v in node:
                visit(v)

    visit(doc)
    if all(v is None for v in best.values()):
        return None
    return best


def _to_float(v):
    try:
        f = float(v)
        return None if f != f or f in (float("inf"), float("-inf")) else f
    except Exception:
        return None


# ---------------------------------------------------------------------------
# Context builders
# ---------------------------------------------------------------------------

def context_from_factories(
    *,
    schema: str,
    conn_factory: Callable[[], Any],
    client_factory: Optional[Callable[[], Any]] = None,
    catalog: str = "iceberg",
    model_name: str = MODEL_NAME,
    base_url: str = BASE_MODEL_URL,
    api_key_env: str = API_KEY_ENV,
    temperature: float = 0.6,
    reasoning: str = "medium",
) -> BaselineContext:
    schema_json = load_schema(schema)
    if client_factory is None:
        def client_factory():  # noqa: E306
            return make_openai_client(base_url=base_url, api_key_env=api_key_env)
    return BaselineContext(
        schema_json=schema_json,
        trino_schema=schema,
        catalog=catalog,
        conn_factory=conn_factory,
        client_factory=client_factory,
        model_name=model_name,
        base_url=base_url,
        temperature=temperature,
        reasoning=reasoning,
    )


def context_from_lakehouse(
    lakehouse,
    *,
    schema: str,
    catalog: str = "iceberg",
    model_name: str = MODEL_NAME,
    base_url: str = BASE_MODEL_URL,
    api_key_env: str = API_KEY_ENV,
    temperature: float = 0.6,
    reasoning: str = "medium",
) -> BaselineContext:
    """
    Build a context from a live ``Lakehouse`` (``Lakehouse.from_release(...)``).
    Connections go through the Lakehouse's Trino host, exactly like
    ``lh.generate_workload``.
    """
    from trino_stack import hive as hive_mod  # local import (needs runtime deps)

    trino_host = lakehouse.trino_host

    def conn_factory():
        return hive_mod.connect_trino(trino_host, schema)

    def client_factory():
        return make_openai_client(base_url=base_url, api_key_env=api_key_env)

    return BaselineContext(
        schema_json=load_schema(schema),
        trino_schema=schema,
        catalog=catalog,
        conn_factory=conn_factory,
        client_factory=client_factory,
        model_name=model_name,
        base_url=base_url,
        temperature=temperature,
        reasoning=reasoning,
    )


# ---------------------------------------------------------------------------
# Workload writer + generation_report (mirrors write_workload_directory)
# ---------------------------------------------------------------------------

def write_baseline_workload(
    *,
    baseline: str,
    workload_name: str,
    queries: List[dict],
    ctx: BaselineContext,
    started_at: datetime,
    pipeline_report: Dict[str, Any],
    workload_root: str | Path = WORKLOAD_ROOT,
    zero_pad: int = 0,
) -> Dict[str, Any]:
    """
    Write ``q<i>.sql`` files + a ``generation_report.json`` for a baseline run.

    ``queries`` is a list of dicts, each with at least ``sql`` and optionally
    ``goal`` / ``selected_tables`` / any baseline-specific metadata (kept under
    each query's ``extra`` key in the report).

    ``pipeline_report`` carries the baseline-specific run summary (prompt suite,
    self-correction attempts, cost-distribution alignment, agent schedule, ...).
    """
    ended_at = datetime.now(timezone.utc)
    workload_root = Path(workload_root)
    workload_dir = ensure_dir(workload_root / workload_name)

    def qname(i: int) -> str:
        return f"q{str(i).zfill(zero_pad)}" if zero_pad else f"q{i}"

    per_query_report: List[Dict[str, Any]] = []
    schema_tables = ctx.schema_tables()

    for i, q in enumerate(queries, start=1):
        name = qname(i)
        sql = sanitize_sql(q.get("sql", ""))
        sql_path = workload_dir / f"{name}.sql"
        sql_path.write_text(sql.strip() + "\n", encoding="utf-8")

        feats = query_features(sql)
        entry = {
            "query_name": name,
            "file": str(sql_path),
            "sql": sql,
            "goal": q.get("goal", ""),
            "selected_tables": q.get("selected_tables", feats.get("tables", [])),
            "metaheuristics": feats,
        }
        if q.get("extra"):
            entry["extra"] = q["extra"]
        per_query_report.append(entry)

    workload_meta = workload_metaheuristics(
        [e["metaheuristics"] for e in per_query_report],
        schema_tables=schema_tables,
    )

    report = {
        "baseline": baseline,
        "workload_name": workload_name,
        "workload_dir": str(workload_dir),
        "created_at_utc": started_at.isoformat(),
        "completed_at_utc": ended_at.isoformat(),
        "duration_s": (ended_at - started_at).total_seconds(),
        "num_queries": len(per_query_report),
        "model": {
            "name": ctx.model_name,
            "base_url": ctx.base_url,
            "temperature": ctx.temperature,
            "reasoning": ctx.reasoning,
        },
        "schema": {
            "catalog": ctx.catalog,
            "schema": ctx.trino_schema,
            "dataset_name": ctx.schema_json.get("name"),
            "num_tables": len(schema_tables),
        },
        "pipeline": pipeline_report,
        "workload_metaheuristics": workload_meta,
        "queries": per_query_report,
    }

    report_path = workload_dir / "generation_report.json"
    report_path.write_text(json.dumps(report, indent=2, default=str), encoding="utf-8")
    return report
