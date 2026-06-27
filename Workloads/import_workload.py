from __future__ import annotations

from pathlib import Path
from typing import List, Tuple
from trino_stack.config import WORKLOAD_ROOT

from pathlib import Path
from typing import List, Tuple


def split_one_query_per_line_to_dir(
    input_sql_path: str | Path,
    workload_name: str | Path,
    *,
    prefix: str = "q",
    start_index: int = 1,
    zero_pad: int = 0,
    skip_empty: bool = True,
    skip_comment_prefixes: tuple[str, ...] = ("--", "#"),
    add_trailing_semicolon: bool = False,
    strip_trailing_semicolon: bool = True,
    newline: str = "\n",
) -> List[Tuple[str, Path]]:
    """
    Reads a file where each line is a full SQL query, and writes each query to its own file:
      <out_dir>/<prefix><X>.sql

    Semicolon handling:
      - add_trailing_semicolon=True  → ensure query ends with ';'
      - strip_trailing_semicolon=True → remove exactly one trailing ';'
      - both False → preserve input
      - both True → error
    """
    if add_trailing_semicolon and strip_trailing_semicolon:
        raise ValueError(
            "add_trailing_semicolon and strip_trailing_semicolon "
            "cannot both be True"
        )

    input_sql_path = Path(input_sql_path)
    out_dir = Path(WORKLOAD_ROOT) / workload_name
    out_dir.mkdir(parents=True, exist_ok=True)

    written: List[Tuple[str, Path]] = []

    with input_sql_path.open("r", encoding="utf-8", errors="replace") as f:
        i = start_index
        for raw in f:
            line = raw.strip()

            if skip_empty and not line:
                continue
            if skip_comment_prefixes and any(line.startswith(p) for p in skip_comment_prefixes):
                continue

            # --- semicolon handling ---
            if strip_trailing_semicolon:
                line = line.rstrip()
                if line.endswith(";"):
                    line = line[:-1].rstrip()

            elif add_trailing_semicolon:
                if not line.rstrip().endswith(";"):
                    line = line.rstrip() + ";"

            qnum = f"{i:0{zero_pad}d}" if zero_pad > 0 else str(i)
            qid = f"{prefix}{qnum}"
            out_path = out_dir / f"{qid}.sql"

            out_path.write_text(line + newline, encoding="utf-8")
            written.append((qid, out_path))
            i += 1

    return written



# Example:
# from Workloads.import_workload import *
# source = "/mnt/primary/Mini-project/Apache/System/Predict_Energy/trino/zero-shot-data/workloads/tpcds/paper2_workload.sql"
# files = split_one_query_per_line_to_dir(source, workload_name="tpcds_1000", zero_pad=0)
