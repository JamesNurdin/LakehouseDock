"""
main -- the public API surface (what trino_stack/lakehouse.py imports).

Wires the concept modules into the v8 default generator and re-exports the exact
names the old query_generator_v*.py modules exposed, so lakehouse.py can switch
with a one-line import change:

    from workload_generation.src.main import (
        load_schema, make_openai_client, warm_up_model,
        generate_query, generate_query_batch, write_workload_directory,
        fetch_table_columns, fetch_schema_table_columns, DiversityTracker,
    )

Default policy = the v8 FeedbackPolicy; default tracker = DiversityTracker.
Experiments pass their own via generate_query_batch(..., tracker=, policy=).
``feedback_enabled=False`` on the tracker -> the loop is inert -> == v6.
"""

from __future__ import annotations

from .schema import (
    load_schema, fetch_table_columns, fetch_schema_table_columns,
)
from .llm import make_openai_client, warm_up_model
from .diversity_tracker import DiversityTracker
from .feedback import FeedbackPolicy
from .pipeline import generate_query, generate_query_batch
from .report import write_workload_directory

__all__ = [
    "load_schema", "make_openai_client", "warm_up_model",
    "generate_query", "generate_query_batch", "write_workload_directory",
    "fetch_table_columns", "fetch_schema_table_columns",
    "DiversityTracker", "FeedbackPolicy",
]
