#!/usr/bin/env python3
"""
Evaluate BigBenchV2 HiveQL -> Trino/Iceberg SQL ports with an LLM judge.

For each q*.hql file, this script finds the corresponding q*.sql file, gives
both files to the model, and asks whether the Trino SQL is a faithful,
read-only Trino/Iceberg port of the original HiveQL query.

It writes:
  - llm_equivalence_report.json
  - llm_equivalence_summary.txt

Typical usage:

  PYTHONPATH=/mnt/primary/Main:$PYTHONPATH python check_bigbenchv2_ports.py \
    --hql-dir /mnt/primary/Main/Datasets/BigBenchV2/queries \
    --sql-dir /mnt/primary/Main/Workloads/bigbenchv2_trino \
    --blacklist q1,q10,q18,q27,q29,q30 \
    --model-name gpt-oss-120b \
    --temperature 0.0

Optional: include Trino EXPLAIN validation before judging:

  PYTHONPATH=/mnt/primary/Main:$PYTHONPATH python check_bigbenchv2_ports.py \
    --hql-dir /mnt/primary/Main/Datasets/BigBenchV2/queries \
    --sql-dir /mnt/primary/Main/Workloads/bigbenchv2_trino \
    --blacklist q1,q10,q18,q27,q29,q30 \
    --validate \
    --trino-host trino-service-lakehouse-d.pgr24james.svc.cluster.local \
    --catalog iceberg \
    --schema bigbenchv2_sf1
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from dataclasses import dataclass, asdict, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Optional

try:
    from openai import (
        OpenAI,
        InternalServerError,
        APIConnectionError,
        RateLimitError,
        APITimeoutError,
    )
except Exception as e:
    OpenAI = None
    InternalServerError = APIConnectionError = RateLimitError = APITimeoutError = Exception
    print(f"WARNING: OpenAI import failed: {e}", file=sys.stderr)

try:
    from trino_stack.config import MODEL_NAME, BASE_MODEL_URL, API_KEY_ENV
except Exception:
    MODEL_NAME = "gpt-oss-120b"
    BASE_MODEL_URL = "http://api.llm.apps.os.dcs.gla.ac.uk/v1"
    API_KEY_ENV = "OPENAI_API_KEY"


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

NON_READ_ONLY_RE = re.compile(
    r"\b(create|drop|insert|delete|update|merge|alter|truncate|call)\b",
    re.IGNORECASE,
)

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


JUDGE_INSTRUCTIONS = """
You are an expert SQL workload reviewer.

Your task is to compare an original BigBenchV2 HiveQL query with a proposed
Trino/Iceberg SQL port.

Decide whether the Trino SQL is a valid and reasonably faithful port.

Important context:
- The original HiveQL may include Hive-only execution wrappers such as SET,
  USE, DROP TABLE, CREATE TABLE, INSERT INTO TABLE, CREATE VIEW, temporary
  tables/views, ROW FORMAT, STORED AS TEXTFILE, CLUSTER BY, and result table
  creation. These wrappers do not need to appear in the Trino version.
- The Trino port should normally be a single read-only SELECT or WITH ... SELECT
  query suitable for a workload runner.
- It is acceptable for temporary/result-table logic to be inlined as CTEs.
- It is acceptable for Hive variables such as ${hiveconf:x} to be replaced with
  literal constants when the value is present in the HiveQL.
- It is acceptable for Hive functions to be rewritten to Trino equivalents:
  unix_timestamp -> to_unixtime(CAST(... AS timestamp));
  collect_list -> array_agg;
  array_contains -> contains;
  explode -> CROSS JOIN UNNEST;
  json_tuple/lateral view -> split/raw-line parsing or json_extract_scalar,
  depending on how web_logs is represented.
- For this local import, web_logs is a raw one-column table with column line.
  The common pipe-delimited mapping is:
    element_at(split(line, '|'), 1) -> wl_id
    element_at(split(line, '|'), 2) -> wl_customer_id
    element_at(split(line, '|'), 3) -> wl_item_id
    element_at(split(line, '|'), 4) -> wl_webpage_name
    element_at(split(line, '|'), 5) -> wl_timestamp
- The port does not have to preserve materialisation side effects, table names
  for intermediate result tables, or storage formats.
- The port should use the target Iceberg catalog/schema tables where possible.
- For queries originally using external Java/Python/UDF logic, mark as not
  directly comparable unless the SQL clearly documents and implements a
  reasonable semantic replacement.

Be strict about:
- invented tables or columns,
- unresolved Hive syntax in the Trino SQL,
- unresolved ${hiveconf:...} placeholders,
- non-read-only SQL if the port is intended for a workload runner,
- SQL that validates syntactically but changes the analytical meaning,
- using JSON extraction on web_logs when the source is actually pipe-delimited,
  unless the SQL also handles the pipe-delimited representation.

Return only valid JSON matching the schema.
""".strip()


JUDGE_PROMPT = """
Query name: {query_name}

Target environment:
- Catalog: {catalog}
- Schema: {schema}
- Expected base tables: {base_tables}
- Trino EXPLAIN validation status: {validation_status}
- Trino EXPLAIN error, if any: {validation_error}

Original HiveQL:
```sql
{hql}
```

Proposed Trino/Iceberg SQL:
```sql
{sql}
```

Assess whether the proposed Trino SQL is a correct port of the original query.
""".strip()


@dataclass
class JudgeResult:
    query_name: str
    hql_file: str
    sql_file: Optional[str]
    status: str
    verdict: str = "not_judged"  # correct, likely_correct, uncertain, incorrect, missing_sql, blacklisted, model_failed
    confidence: float = 0.0
    reason: str = ""
    issues: list[str] = field(default_factory=list)
    suggested_action: str = ""
    validation_status: Optional[str] = None
    validation_error: Optional[str] = None
    hard_blockers: list[str] = field(default_factory=list)
    non_read_only_keywords: list[str] = field(default_factory=list)
    model_response: Optional[dict[str, Any]] = None


def query_sort_key(path: Path | str) -> tuple[int, str]:
    name = Path(path).stem
    m = re.search(r"q(\d+)", name, flags=re.IGNORECASE)
    return (int(m.group(1)) if m else 10**9, name)


def normalise_query_name(name: str) -> str:
    name = name.strip()
    if name.endswith(".hql") or name.endswith(".sql"):
        name = Path(name).stem
    return name.lower()


def parse_name_list(items: str | list[str] | None) -> set[str]:
    if not items:
        return set()
    if isinstance(items, str):
        raw = re.split(r"[,\s]+", items.strip()) if items.strip() else []
    else:
        raw = items
    return {normalise_query_name(x) for x in raw if x.strip()}


def read_text(path: Path, max_chars: Optional[int] = None) -> str:
    text = path.read_text(encoding="utf-8", errors="ignore")
    if max_chars and len(text) > max_chars:
        half = max_chars // 2
        return (
            text[:half]
            + "\n\n/* ... TRUNCATED MIDDLE BY CHECK SCRIPT ... */\n\n"
            + text[-half:]
        )
    return text


def strip_sql_comments(sql: str) -> str:
    lines = []
    for line in sql.splitlines():
        stripped = line.strip()
        if stripped.startswith("--"):
            continue
        if "--" in line:
            line = line.split("--", 1)[0]
        lines.append(line)
    return "\n".join(lines)


def find_hard_blocker_lines(sql: str) -> list[str]:
    out = []
    for i, line in enumerate(sql.splitlines(), start=1):
        if HARD_BLOCKER_RE.search(line):
            out.append(f"{i}: {line.strip()}")
    return out


def find_non_read_only_keywords(sql: str) -> list[str]:
    clean = strip_sql_comments(sql)
    return sorted({m.group(1).upper() for m in NON_READ_ONLY_RE.finditer(clean)})


def make_openai_client(base_url: str, api_key_env: str) -> OpenAI:
    if OpenAI is None:
        raise RuntimeError("openai package is not available")
    api_key = os.environ.get(api_key_env)
    if not api_key:
        # OpenAI-compatible local gateways often ignore the key but the SDK needs one.
        api_key = "EMPTY"
    return OpenAI(base_url=base_url, api_key=api_key)


def call_with_retry(fn, *, max_retries: int = 8, base_sleep_s: float = 10.0, max_sleep_s: float = 120.0):
    last_error = None
    retryable = (InternalServerError, APIConnectionError, RateLimitError, APITimeoutError)

    for attempt in range(max_retries):
        try:
            return fn()
        except retryable as e:
            last_error = e
            sleep_s = min(base_sleep_s * (2 ** attempt), max_sleep_s)
            print(f"[API retry {attempt + 1}/{max_retries}] {type(e).__name__}: {e}")
            print(f"Sleeping {sleep_s:.1f}s before retry...")
            time.sleep(sleep_s)

    raise RuntimeError(f"API call failed after {max_retries} retries") from last_error


def warm_up_model(client: OpenAI, model_name: str) -> None:
    def _call():
        return client.responses.create(
            model=model_name,
            input="Return only the word ready.",
            temperature=0,
            store=False,
        )

    result = call_with_retry(_call)
    print(f"Model warm-up response: {result.output_text.strip()}")


def judge_pair(
    *,
    client: OpenAI,
    model_name: str,
    temperature: float,
    query_name: str,
    hql: str,
    sql: str,
    catalog: str,
    schema: str,
    validation_status: Optional[str],
    validation_error: Optional[str],
) -> dict[str, Any]:
    prompt = JUDGE_PROMPT.format(
        query_name=query_name,
        catalog=catalog,
        schema=schema,
        base_tables=", ".join(BASE_TABLES),
        validation_status=validation_status or "not_run",
        validation_error=validation_error or "",
        hql=hql,
        sql=sql,
    )

    def _call():
        return client.responses.create(
            model=model_name,
            instructions=JUDGE_INSTRUCTIONS,
            input=prompt,
            text={
                "format": {
                    "type": "json_schema",
                    "name": "bigbench_port_judgement",
                    "strict": True,
                    "schema": {
                        "type": "object",
                        "properties": {
                            "verdict": {
                                "type": "string",
                                "enum": ["correct", "likely_correct", "uncertain", "incorrect"]
                            },
                            "confidence": {
                                "type": "number",
                                "minimum": 0,
                                "maximum": 1
                            },
                            "reason": {
                                "type": "string"
                            },
                            "issues": {
                                "type": "array",
                                "items": {"type": "string"}
                            },
                            "suggested_action": {
                                "type": "string"
                            },
                            "semantic_summary_hive": {
                                "type": "string"
                            },
                            "semantic_summary_trino": {
                                "type": "string"
                            },
                            "material_differences": {
                                "type": "array",
                                "items": {"type": "string"}
                            }
                        },
                        "required": [
                            "verdict",
                            "confidence",
                            "reason",
                            "issues",
                            "suggested_action",
                            "semantic_summary_hive",
                            "semantic_summary_trino",
                            "material_differences"
                        ],
                        "additionalProperties": False
                    }
                }
            },
            temperature=temperature,
            store=False,
        )

    result = call_with_retry(_call)
    return json.loads(result.output_text)


def validate_sql_with_trino(sql: str, *, host: str, schema: str) -> tuple[str, Optional[str]]:
    try:
        from trino_stack import hive as hive_mod
        conn = hive_mod.connect_trino(host, schema=schema)
        cur = conn.cursor()
        try:
            clean_sql = sql.strip().rstrip(";")
            cur.execute("EXPLAIN " + clean_sql)
            cur.fetchall()
            return "passed", None
        finally:
            try:
                cur.close()
            finally:
                conn.close()
    except Exception as e:
        return "failed", str(e)


def find_sql_file(sql_dir: Path, query_name: str) -> Optional[Path]:
    candidates = [
        sql_dir / f"{query_name}.sql",
        sql_dir / f"{query_name}.validated.sql",
        sql_dir / f"{query_name}.failed.sql",
    ]
    for c in candidates:
        if c.exists():
            return c
    matches = sorted(sql_dir.glob(f"{query_name}*.sql"), key=query_sort_key)
    return matches[0] if matches else None


def run(args: argparse.Namespace) -> dict[str, Any]:
    started_at = datetime.now(timezone.utc)

    hql_dir = Path(args.hql_dir).resolve()
    sql_dir = Path(args.sql_dir).resolve()
    output_dir = Path(args.output_dir).resolve() if args.output_dir else sql_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    blacklist = parse_name_list(args.blacklist)
    only = parse_name_list(args.only)

    if not hql_dir.is_dir():
        raise FileNotFoundError(f"HiveQL directory not found: {hql_dir}")
    if not sql_dir.is_dir():
        raise FileNotFoundError(f"SQL directory not found: {sql_dir}")

    client = make_openai_client(args.base_url, args.api_key_env)

    if args.warmup:
        warm_up_model(client, args.model_name)

    hql_files = sorted(hql_dir.glob(args.pattern), key=query_sort_key)
    results: list[JudgeResult] = []

    for hql_path in hql_files:
        query_name = normalise_query_name(hql_path.stem)

        if only and query_name not in only:
            continue

        hql_text_full = hql_path.read_text(encoding="utf-8", errors="ignore")
        hard_blockers = find_hard_blocker_lines(hql_text_full)

        if query_name in blacklist:
            print(f"SKIP {query_name}: blacklisted")
            results.append(JudgeResult(
                query_name=query_name,
                hql_file=str(hql_path),
                sql_file=None,
                status="blacklisted",
                verdict="blacklisted",
                reason="Query is explicitly blacklisted.",
                hard_blockers=hard_blockers,
            ))
            continue

        sql_path = find_sql_file(sql_dir, query_name)
        if sql_path is None:
            print(f"MISS {query_name}: no SQL file")
            results.append(JudgeResult(
                query_name=query_name,
                hql_file=str(hql_path),
                sql_file=None,
                status="missing_sql",
                verdict="missing_sql",
                reason="No corresponding SQL file was found.",
                hard_blockers=hard_blockers,
            ))
            continue

        print(f"JUDGE {query_name}")

        hql_text = read_text(hql_path, max_chars=args.max_hql_chars)
        sql_text = read_text(sql_path, max_chars=args.max_sql_chars)

        non_read_only_keywords = find_non_read_only_keywords(sql_text)

        validation_status = None
        validation_error = None
        if args.validate:
            if not args.trino_host:
                validation_status = "not_run"
                validation_error = "--validate supplied without --trino-host"
            else:
                validation_status, validation_error = validate_sql_with_trino(
                    sql_text,
                    host=args.trino_host,
                    schema=args.schema,
                )

        try:
            judgement = judge_pair(
                client=client,
                model_name=args.model_name,
                temperature=args.temperature,
                query_name=query_name,
                hql=hql_text,
                sql=sql_text,
                catalog=args.catalog,
                schema=args.schema,
                validation_status=validation_status,
                validation_error=validation_error,
            )

            result = JudgeResult(
                query_name=query_name,
                hql_file=str(hql_path),
                sql_file=str(sql_path),
                status="judged",
                verdict=judgement["verdict"],
                confidence=float(judgement["confidence"]),
                reason=judgement["reason"],
                issues=judgement["issues"],
                suggested_action=judgement["suggested_action"],
                validation_status=validation_status,
                validation_error=validation_error,
                hard_blockers=hard_blockers,
                non_read_only_keywords=non_read_only_keywords,
                model_response=judgement,
            )
            print(f"  -> {result.verdict} ({result.confidence:.2f})")

        except Exception as e:
            result = JudgeResult(
                query_name=query_name,
                hql_file=str(hql_path),
                sql_file=str(sql_path),
                status="model_failed",
                verdict="model_failed",
                confidence=0.0,
                reason=str(e),
                validation_status=validation_status,
                validation_error=validation_error,
                hard_blockers=hard_blockers,
                non_read_only_keywords=non_read_only_keywords,
            )
            print(f"  -> model_failed: {e}")

        results.append(result)

    ended_at = datetime.now(timezone.utc)

    counts = {
        "total_seen": len(results),
        "judged": sum(r.status == "judged" for r in results),
        "correct": sum(r.verdict == "correct" for r in results),
        "likely_correct": sum(r.verdict == "likely_correct" for r in results),
        "uncertain": sum(r.verdict == "uncertain" for r in results),
        "incorrect": sum(r.verdict == "incorrect" for r in results),
        "missing_sql": sum(r.verdict == "missing_sql" for r in results),
        "blacklisted": sum(r.verdict == "blacklisted" for r in results),
        "model_failed": sum(r.verdict == "model_failed" for r in results),
        "validation_passed": sum(r.validation_status == "passed" for r in results),
        "validation_failed": sum(r.validation_status == "failed" for r in results),
    }

    report = {
        "created_at_utc": started_at.isoformat(),
        "completed_at_utc": ended_at.isoformat(),
        "duration_s": (ended_at - started_at).total_seconds(),
        "hql_dir": str(hql_dir),
        "sql_dir": str(sql_dir),
        "output_dir": str(output_dir),
        "catalog": args.catalog,
        "schema": args.schema,
        "trino_host": args.trino_host,
        "model": {
            "name": args.model_name,
            "base_url": args.base_url,
            "temperature": args.temperature,
        },
        "blacklist": sorted(blacklist, key=query_sort_key),
        "only": sorted(only, key=query_sort_key),
        "counts": counts,
        "queries": [asdict(r) for r in results],
    }

    report_path = output_dir / args.report_name
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")

    summary_lines = []
    summary_lines.append("BigBenchV2 HiveQL -> Trino/Iceberg LLM equivalence check")
    summary_lines.append("=" * 72)
    summary_lines.append(f"HiveQL dir: {hql_dir}")
    summary_lines.append(f"SQL dir:    {sql_dir}")
    summary_lines.append(f"Created:    {report['created_at_utc']}")
    summary_lines.append("")
    summary_lines.append("Counts:")
    for k, v in counts.items():
        summary_lines.append(f"  {k}: {v}")
    summary_lines.append("")

    for verdict in ["incorrect", "uncertain", "model_failed", "missing_sql", "likely_correct", "correct"]:
        subset = [r for r in results if r.verdict == verdict]
        if not subset:
            continue
        summary_lines.append(f"{verdict.upper()}:")
        for r in sorted(subset, key=lambda x: query_sort_key(x.query_name)):
            conf = f"{r.confidence:.2f}" if r.confidence else "-"
            summary_lines.append(f"  {r.query_name} [{conf}] {r.reason}")
            if r.validation_status == "failed":
                summary_lines.append(f"    Trino: {r.validation_error}")
            for issue in r.issues[:5]:
                summary_lines.append(f"    - {issue}")
            if r.suggested_action:
                summary_lines.append(f"    action: {r.suggested_action}")
        summary_lines.append("")

    summary_path = output_dir / args.summary_name
    summary_path.write_text("\n".join(summary_lines) + "\n", encoding="utf-8")

    print("Done.")
    print(f"Report:  {report_path}")
    print(f"Summary: {summary_path}")
    print("Counts:")
    for k, v in counts.items():
        print(f"  {k}: {v}")

    return report


def parse_args(argv: Optional[list[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Use an LLM to judge whether Trino SQL ports match original BigBenchV2 HiveQL files."
    )

    parser.add_argument("--hql-dir", required=True, help="Directory containing original q*.hql files.")
    parser.add_argument("--sql-dir", required=True, help="Directory containing generated q*.sql files.")
    parser.add_argument("--pattern", default="q*.hql", help="HiveQL input glob. Default: q*.hql")
    parser.add_argument("--output-dir", default=None, help="Where to write report files. Default: sql-dir")

    parser.add_argument("--catalog", default="iceberg")
    parser.add_argument("--schema", default="bigbenchv2_sf1")
    parser.add_argument("--blacklist", default="q1,q10,q18,q27,q29,q30")
    parser.add_argument("--only", default="", help="Optional comma/space-separated subset, e.g. q2,q4")

    parser.add_argument("--validate", action="store_true", help="Run EXPLAIN against Trino before model judgement.")
    parser.add_argument("--trino-host", default=None)

    parser.add_argument("--model-name", default=MODEL_NAME)
    parser.add_argument("--base-url", default=BASE_MODEL_URL)
    parser.add_argument("--api-key-env", default=API_KEY_ENV)
    parser.add_argument("--temperature", type=float, default=0.0)
    parser.add_argument("--warmup", action="store_true")

    parser.add_argument("--max-hql-chars", type=int, default=30000)
    parser.add_argument("--max-sql-chars", type=int, default=30000)

    parser.add_argument("--report-name", default="llm_equivalence_report.json")
    parser.add_argument("--summary-name", default="llm_equivalence_summary.txt")

    return parser.parse_args(argv)


def main(argv: Optional[list[str]] = None) -> int:
    args = parse_args(argv)
    run(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
