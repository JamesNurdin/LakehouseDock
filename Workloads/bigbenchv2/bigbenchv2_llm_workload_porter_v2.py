#!/usr/bin/env python3
"""
LLM-assisted BigBenchV2 HiveQL -> Trino/Iceberg workload porter.

This script reads BigBenchV2 q*.hql files, skips a configurable blacklist, asks an
OpenAI-compatible model to rewrite each remaining HiveQL file into a single
read-only Trino/Iceberg SELECT query, validates the query with Trino EXPLAIN,
and iteratively sends Trino errors back to the model until the query validates
or the repair budget is exhausted.

Important design choice:
- Output workload files are SELECT/WITH ... SELECT statements only.
- DDL/DML/materialisation statements such as CREATE, DROP, INSERT, CTAS, CALL,
  DELETE, UPDATE, MERGE, ALTER, TRUNCATE are rejected before Trino validation.
- Hive temp tables/views should be inlined as CTEs.

Example:

PYTHONPATH=/mnt/primary/Main:$PYTHONPATH python bigbenchv2_llm_workload_porter_v2.py \
  --source-dir /mnt/primary/Main/Datasets/BigBenchV2/queries \
  --workload-name bigbenchv2_trino_retry \
  --catalog iceberg \
  --schema bigbenchv2_sf1 \
  --trino-host trino-service-lakehouse-d.pgr24james.svc.cluster.local \
  --blacklist q1,q10,q18,q27,q29,q30 \
  --only q2,q3,q4,q13,q15,q20,q28 \
  --max-repair-attempts 8 \
  --temperature 0.15
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Optional project imports
# ---------------------------------------------------------------------------

try:
    from trino_stack.config import WORKLOAD_ROOT, MODEL_NAME, BASE_MODEL_URL, API_KEY_ENV
except Exception:
    WORKLOAD_ROOT = "/mnt/primary/Main/Workloads"
    MODEL_NAME = os.environ.get("MODEL_NAME", "gpt-oss-120b")
    BASE_MODEL_URL = os.environ.get("BASE_MODEL_URL", "http://api.llm.apps.os.dcs.gla.ac.uk/v1")
    API_KEY_ENV = os.environ.get("API_KEY_ENV", "OPENAI_API_KEY")

try:
    from trino_stack.workload import ensure_dir
except Exception:
    def ensure_dir(path):
        path = Path(path)
        path.mkdir(parents=True, exist_ok=True)
        return path

try:
    from trino_stack.query_generator import make_openai_client as stack_make_openai_client
    from trino_stack.query_generator import call_with_retry as stack_call_with_retry
    from trino_stack.query_generator import warm_up_model as stack_warm_up_model
except Exception:
    stack_make_openai_client = None
    stack_call_with_retry = None
    stack_warm_up_model = None

try:
    from trino_stack import hive as hive_mod
except Exception:
    hive_mod = None

try:
    from openai import OpenAI
    from openai import InternalServerError, APIConnectionError, RateLimitError, APITimeoutError
except Exception:
    OpenAI = None
    InternalServerError = APIConnectionError = RateLimitError = APITimeoutError = Exception


# ---------------------------------------------------------------------------
# Constants and detection patterns
# ---------------------------------------------------------------------------

BASE_TABLES = [
    "customers",
    "items",
    "product_reviews",
    "web_pages",
    "web_sales",
    "store_sales",
    "stores",
    "web_logs",
]

DEFAULT_BLACKLIST = "q1,q10,q18,q27,q29,q30"

HARD_BLOCKER_RE = re.compile(
    r"add\s+(jar|file)|"
    r"create\s+temporary\s+function|"
    r"transform\s*\(|"
    r"\breduce\b|"
    r"using\s+['\"]?(java|python|perl|ruby)|"
    r"extract_sentiment|extract_negsentiment|find_company|"
    r"bigbenchqueriesmr\.jar|sentimentudf|textclassifier|mahout|streaming",
    re.IGNORECASE,
)

FORBIDDEN_SQL_RE = re.compile(
    r"\b(create|drop|insert|delete|update|merge|alter|truncate|call|grant|revoke|refresh|analyze)\b",
    re.IGNORECASE,
)

MULTI_STATEMENT_RE = re.compile(r";\s*\S", re.DOTALL)


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------

@dataclass
class Attempt:
    attempt: int
    validation_status: str
    sql: str
    error: Optional[str] = None
    model_notes: list[str] = field(default_factory=list)


@dataclass
class QueryResult:
    query_name: str
    source_file: str
    status: str
    output_file: Optional[str] = None
    goal: str = ""
    blockers: list[str] = field(default_factory=list)
    attempts: list[Attempt] = field(default_factory=list)
    final_error: Optional[str] = None


# ---------------------------------------------------------------------------
# Basic helpers
# ---------------------------------------------------------------------------

def query_sort_key(path: Path) -> tuple[int, str]:
    m = re.search(r"q(\d+)", path.stem, flags=re.IGNORECASE)
    return (int(m.group(1)) if m else 10**9, path.name)


def normalise_query_name(name: str) -> str:
    name = name.strip()
    if not name:
        return name
    if name.endswith((".hql", ".sql")):
        name = Path(name).stem
    return name.lower()


def parse_name_set(value: str | None) -> set[str]:
    if not value:
        return set()
    return {normalise_query_name(x) for x in re.split(r"[,\s]+", value.strip()) if x.strip()}


def strip_full_line_comments(sql: str) -> str:
    return "\n".join(line for line in sql.splitlines() if not line.strip().startswith("--"))


def blocker_lines(sql_no_comments: str) -> list[str]:
    out = []
    for i, line in enumerate(sql_no_comments.splitlines(), start=1):
        if HARD_BLOCKER_RE.search(line):
            out.append(f"{i}: {line.strip()}")
    return out


def sanitize_model_sql(sql: str) -> str:
    if not sql:
        return ""
    sql = sql.strip()
    sql = re.sub(r"^```(?:sql)?\s*", "", sql, flags=re.IGNORECASE)
    sql = re.sub(r"\s*```$", "", sql)
    sql = sql.strip()

    # If the model adds prose before the SQL, try to keep from first WITH/SELECT.
    m = re.search(r"(?is)\b(with|select)\b", sql)
    if m and m.start() > 0:
        sql = sql[m.start():].strip()

    # Remove one trailing semicolon. Internal semicolons remain and are rejected.
    sql = re.sub(r";+\s*$", "", sql).strip()
    return sql


def client_side_validate_sql(sql: str) -> tuple[bool, Optional[str]]:
    s = sanitize_model_sql(sql)
    if not s:
        return False, "Model returned empty SQL."

    if not re.match(r"(?is)^\s*(with|select)\b", s):
        return False, "Output must be a single read-only SELECT query starting with SELECT or WITH."

    if FORBIDDEN_SQL_RE.search(s):
        bad = sorted(set(m.group(1).upper() for m in FORBIDDEN_SQL_RE.finditer(s)))
        return False, f"Forbidden non-read-only SQL keyword(s): {', '.join(bad)}. Inline all temp/result tables as CTEs and return only SELECT."

    if MULTI_STATEMENT_RE.search(s):
        return False, "Multiple statements detected. Return exactly one SELECT/WITH query with no internal semicolons."

    return True, None


def build_table_context(catalog: str, schema: str) -> str:
    q = lambda t: f"{catalog}.{schema}.{t}"
    return f"""
Available Trino/Iceberg tables:
- {q('customers')}(c_customer_id, c_name)
- {q('items')}(i_item_id, i_name, i_category, i_category_id, i_brand, i_brand_id, i_price)
- {q('product_reviews')}(pr_review_id, pr_item_id, pr_review_date, pr_rating, pr_content)
- {q('web_pages')}(w_web_page_id, w_web_page_name, w_web_page_type)
- {q('web_sales')}(ws_order_number, ws_item_id, ws_customer_id, ws_quantity, ws_sales_price)
- {q('store_sales')}(ss_ticket_number, ss_item_id, ss_customer_id, ss_store_id, ss_quantity, ss_sales_price)
- {q('stores')}(s_store_id, s_store_name)
- {q('web_logs')}(line)

web_logs parsing guidance:
The imported web_logs table stores each raw click-log row as a single pipe-delimited VARCHAR column called line.
Use Trino functions such as split(line, '|'), element_at(...), NULLIF(...), TRY_CAST(...).
The observed field positions are:
- element_at(split(line, '|'), 1): log id
- element_at(split(line, '|'), 2): customer id
- element_at(split(line, '|'), 3): item id
- element_at(split(line, '|'), 4): web page name
- element_at(split(line, '|'), 5): timestamp string
Trino arrays are 1-indexed.
Use TRY_CAST(NULLIF(element_at(split(line, '|'), n), '') AS bigint) for numeric fields.
Use TRY_CAST(NULLIF(element_at(split(line, '|'), 5), '') AS timestamp) for timestamps.
""".strip()


# ---------------------------------------------------------------------------
# OpenAI-compatible helpers
# ---------------------------------------------------------------------------

def make_client(base_url: str, api_key_env: str):
    if stack_make_openai_client is not None:
        return stack_make_openai_client(base_url=base_url, api_key_env=api_key_env)
    if OpenAI is None:
        raise RuntimeError("openai package is not available and trino_stack.query_generator could not be imported")
    return OpenAI(base_url=base_url, api_key=os.environ[api_key_env])


def call_with_retry(fn, *, max_retries: int = 8, base_sleep_s: float = 10.0, max_sleep_s: float = 120.0):
    if stack_call_with_retry is not None:
        return stack_call_with_retry(fn, max_retries=max_retries, base_sleep_s=base_sleep_s, max_sleep_s=max_sleep_s)

    last_error = None
    retry_errors = (InternalServerError, APIConnectionError, RateLimitError, APITimeoutError)
    for attempt in range(max_retries):
        try:
            return fn()
        except retry_errors as e:
            last_error = e
            sleep_s = min(base_sleep_s * (2 ** attempt), max_sleep_s)
            print(f"[API retry {attempt + 1}/{max_retries}] {type(e).__name__}: {e}")
            print(f"Sleeping {sleep_s:.1f}s before retry...")
            time.sleep(sleep_s)
    raise RuntimeError(f"API call failed after {max_retries} retries") from last_error


def warm_up(client, model_name: str):
    if stack_warm_up_model is not None:
        return stack_warm_up_model(client, model_name=model_name)

    def _call():
        return client.responses.create(model=model_name, input="Return only the word ready.", temperature=0, store=False)
    result = call_with_retry(_call)
    print(f"Model warm-up response: {result.output_text.strip()}")


def response_schema() -> dict:
    return {
        "type": "object",
        "properties": {
            "sql": {"type": "string"},
            "goal": {"type": "string"},
            "notes": {"type": "array", "items": {"type": "string"}},
        },
        "required": ["sql", "goal", "notes"],
        "additionalProperties": False,
    }


def model_rewrite(
    *,
    client,
    model_name: str,
    temperature: float,
    query_name: str,
    source_hql: str,
    catalog: str,
    schema: str,
    previous_sql: Optional[str] = None,
    previous_error: Optional[str] = None,
):
    table_context = build_table_context(catalog, schema)

    instructions = f"""
You are porting BigBenchV2 HiveQL queries into Trino SQL over Iceberg tables.

Return JSON only with fields: sql, goal, notes.

Hard requirements for sql:
- Return exactly one read-only Trino query.
- The SQL must start with SELECT or WITH.
- Do not use CREATE, DROP, INSERT, DELETE, UPDATE, MERGE, ALTER, TRUNCATE, CALL, ANALYZE, GRANT, REVOKE, or REFRESH.
- Do not create result tables, temp tables, temporary views, or persistent views.
- Inline all Hive temp tables/views/result-table logic as CTEs.
- Remove USE, SET, ADD JAR, ADD FILE, ROW FORMAT, STORED AS, and Hive result-table wrappers.
- Do not use Hive-only syntax: LATERAL VIEW, json_tuple, explode, collect_list, array_contains, unix_timestamp, matchpath.
- Use Trino equivalents: CROSS JOIN UNNEST, array_agg, contains, to_unixtime, TRY_CAST, date_diff, regexp functions, CTEs.
- Use fully qualified table names with catalog/schema: {catalog}.{schema}.<table>.
- Avoid SELECT * in the final output.
- The query must be valid under EXPLAIN in Trino.
- Do not include markdown fences or explanation inside the sql string.

For path/session queries:
- Prefer pure SQL approximations using CTEs, window functions, grouping, and arrays.
- If Hive matchpath appears, rewrite the semantics using standard Trino SQL/window logic rather than MATCH_RECOGNIZE unless you are certain the syntax is valid.

{table_context}
""".strip()

    prompt_parts = [
        f"Query name: {query_name}",
        "Original BigBenchV2 HiveQL:",
        source_hql,
    ]
    if previous_sql is not None or previous_error is not None:
        prompt_parts.extend([
            "The previous attempt failed validation.",
            "Previous SQL:",
            previous_sql or "",
            "Validation error:",
            previous_error or "",
            "Repair the SQL. Keep it as one read-only SELECT/WITH query only.",
        ])

    def _call():
        return client.responses.create(
            model=model_name,
            instructions=instructions,
            input="\n\n".join(prompt_parts),
            text={
                "format": {
                    "type": "json_schema",
                    "name": "bigbenchv2_trino_port",
                    "strict": True,
                    "schema": response_schema(),
                }
            },
            temperature=temperature,
            store=False,
        )

    result = call_with_retry(_call)
    data = json.loads(result.output_text)
    data["sql"] = sanitize_model_sql(data.get("sql", ""))
    data["goal"] = data.get("goal", "")
    data["notes"] = data.get("notes", [])
    return data


# ---------------------------------------------------------------------------
# Trino validation
# ---------------------------------------------------------------------------

def validate_with_trino(sql: str, *, host: str, schema: str) -> tuple[bool, Optional[str]]:
    if hive_mod is None:
        return False, "Could not import trino_stack.hive; set PYTHONPATH=/mnt/primary/Main:$PYTHONPATH"
    try:
        conn = hive_mod.connect_trino(host, schema=schema)
        cur = conn.cursor()
        try:
            cur.execute("EXPLAIN " + sql.strip().rstrip(";"))
            cur.fetchall()
            return True, None
        finally:
            try:
                cur.close()
            finally:
                conn.close()
    except Exception as e:
        return False, str(e)


# ---------------------------------------------------------------------------
# Main workflow
# ---------------------------------------------------------------------------

def process_one_query(args, client, src: Path) -> QueryResult:
    query_name = normalise_query_name(src.stem)
    source_hql = src.read_text(encoding="utf-8", errors="ignore")
    no_comments = strip_full_line_comments(source_hql)
    blockers = blocker_lines(no_comments)

    result = QueryResult(
        query_name=query_name,
        source_file=str(src),
        status="pending",
        blockers=blockers,
    )

    blacklist = parse_name_set(args.blacklist)
    if query_name in blacklist:
        result.status = "blacklisted"
        return result

    if args.skip_detected_hard and blockers:
        result.status = "skipped_hard_blocker"
        result.final_error = "Detected hard Hive external execution blocker."
        return result

    previous_sql = None
    previous_error = None
    total_attempts = args.max_repair_attempts + 1

    for attempt_no in range(1, total_attempts + 1):
        try:
            data = model_rewrite(
                client=client,
                model_name=args.model_name,
                temperature=args.temperature,
                query_name=query_name,
                source_hql=source_hql,
                catalog=args.catalog,
                schema=args.schema,
                previous_sql=previous_sql,
                previous_error=previous_error,
            )
        except Exception as e:
            result.status = "model_failed"
            result.final_error = str(e)
            return result

        sql = sanitize_model_sql(data["sql"])
        result.goal = data.get("goal", result.goal)
        notes = data.get("notes", [])

        ok, client_error = client_side_validate_sql(sql)
        if not ok:
            result.attempts.append(Attempt(
                attempt=attempt_no,
                validation_status="failed_client_side",
                sql=sql,
                error=client_error,
                model_notes=notes,
            ))
            previous_sql = sql
            previous_error = client_error
            continue

        ok, trino_error = validate_with_trino(sql, host=args.trino_host, schema=args.schema)
        if ok:
            out_path = args.output_dir / f"{query_name}.sql"
            out_path.write_text(sql.strip() + "\n", encoding="utf-8")
            result.status = "validated"
            result.output_file = str(out_path)
            result.attempts.append(Attempt(
                attempt=attempt_no,
                validation_status="passed",
                sql=sql,
                error=None,
                model_notes=notes,
            ))
            return result

        result.attempts.append(Attempt(
            attempt=attempt_no,
            validation_status="failed",
            sql=sql,
            error=trino_error,
            model_notes=notes,
        ))
        previous_sql = sql
        previous_error = trino_error

    failed_path = args.output_dir / f"{query_name}.failed.sql"
    if previous_sql:
        failed_path.write_text(previous_sql.strip() + "\n", encoding="utf-8")
        result.output_file = str(failed_path)
    result.status = "validation_failed"
    result.final_error = previous_error
    return result


def run(args) -> dict:
    started_at = datetime.now(timezone.utc)
    source_dir = Path(args.source_dir).resolve()
    if not source_dir.is_dir():
        raise FileNotFoundError(f"Source directory not found: {source_dir}")

    if args.output_dir:
        output_dir = ensure_dir(Path(args.output_dir).resolve())
        workload_name = output_dir.name
    else:
        workload_name = args.workload_name
        output_dir = ensure_dir(Path(args.workload_root) / workload_name)
    args.output_dir = output_dir

    only = parse_name_set(args.only)
    query_files = sorted(source_dir.glob(args.pattern), key=query_sort_key)
    if only:
        query_files = [p for p in query_files if normalise_query_name(p.stem) in only]

    if not query_files:
        raise FileNotFoundError("No query files selected.")

    client = make_client(args.base_url, args.api_key_env)
    if args.warmup:
        warm_up(client, args.model_name)

    results: list[QueryResult] = []
    for src in query_files:
        qn = normalise_query_name(src.stem)
        if qn in parse_name_set(args.blacklist):
            print(f"SKIP {qn}: blacklisted")
        else:
            print(f"PORT {qn}")

        qr = process_one_query(args, client, src)
        results.append(qr)

        if qr.status == "validated":
            print(f"  -> validated after {len(qr.attempts)} attempt(s)")
        elif qr.status in {"blacklisted", "skipped_hard_blocker"}:
            print(f"  -> {qr.status}")
        else:
            print(f"  -> {qr.status} after {len(qr.attempts)} attempt(s)")
            if qr.final_error:
                print(f"     final error: {str(qr.final_error)[:240]}")

    ended_at = datetime.now(timezone.utc)

    def count_status(s: str) -> int:
        return sum(r.status == s for r in results)

    report = {
        "workload_name": workload_name,
        "source_dir": str(source_dir),
        "output_dir": str(output_dir),
        "created_at_utc": started_at.isoformat(),
        "completed_at_utc": ended_at.isoformat(),
        "duration_s": (ended_at - started_at).total_seconds(),
        "catalog": args.catalog,
        "schema": args.schema,
        "trino_host": args.trino_host,
        "model": {
            "name": args.model_name,
            "base_url": args.base_url,
            "temperature": args.temperature,
            "max_repair_attempts": args.max_repair_attempts,
        },
        "blacklist": sorted(parse_name_set(args.blacklist), key=lambda x: int(x[1:]) if re.match(r"q\d+", x) else 10**9),
        "only": sorted(only, key=lambda x: int(x[1:]) if re.match(r"q\d+", x) else 10**9),
        "counts": {
            "total_seen": len(results),
            "validated": count_status("validated"),
            "blacklisted": count_status("blacklisted"),
            "skipped_hard_blocker": count_status("skipped_hard_blocker"),
            "validation_failed": count_status("validation_failed"),
            "model_failed": count_status("model_failed"),
        },
        "queries": [asdict(r) for r in results],
    }

    report_path = output_dir / "generation_report.json"
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")

    review_lines = []
    for r in results:
        if r.status != "validated":
            review_lines.append(f"{r.query_name}: {r.status}")
            for b in r.blockers:
                review_lines.append(f"  BLOCKER {b}")
            if r.final_error:
                review_lines.append(f"  FINAL {r.final_error}")
        elif r.attempts and len(r.attempts) > 1:
            review_lines.append(f"{r.query_name}: validated after {len(r.attempts)} attempts")
    (output_dir / "needs_review.txt").write_text("\n".join(review_lines) + "\n", encoding="utf-8")

    return report


def parse_args(argv: Optional[list[str]] = None):
    p = argparse.ArgumentParser(description="LLM-assisted BigBenchV2 HiveQL to Trino/Iceberg query porter.")

    p.add_argument("--source-dir", required=True, help="Directory containing q*.hql files.")
    p.add_argument("--pattern", default="q*.hql")

    p.add_argument("--workload-root", default=str(WORKLOAD_ROOT))
    p.add_argument("--workload-name", default="bigbenchv2_trino")
    p.add_argument("--output-dir", default=None)

    p.add_argument("--catalog", default="iceberg")
    p.add_argument("--schema", default="bigbenchv2_sf1")
    p.add_argument("--trino-host", required=True)

    p.add_argument("--blacklist", default=DEFAULT_BLACKLIST)
    p.add_argument("--skip-detected-hard", action="store_true")
    p.add_argument("--only", default=None, help="Comma/space separated query names to process, e.g. q2,q3,q4")

    p.add_argument("--model-name", default=MODEL_NAME)
    p.add_argument("--base-url", default=BASE_MODEL_URL)
    p.add_argument("--api-key-env", default=API_KEY_ENV)
    p.add_argument("--temperature", type=float, default=0.2)
    p.add_argument("--max-repair-attempts", type=int, default=5, help="Number of repairs after the initial attempt.")
    p.add_argument("--warmup", action="store_true")

    return p.parse_args(argv)


def main(argv: Optional[list[str]] = None) -> int:
    args = parse_args(argv)
    report = run(args)

    print("Done.")
    print(f"Output directory: {report['output_dir']}")
    print("Counts:")
    for k, v in report["counts"].items():
        print(f"  {k}: {v}")
    print(f"Report: {Path(report['output_dir']) / 'generation_report.json'}")
    print(f"Review: {Path(report['output_dir']) / 'needs_review.txt'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
