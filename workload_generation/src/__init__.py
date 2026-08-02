"""
workload_generation.src -- the consolidated QueryDock generator (v8 design),
factored by concept. See README.md for architecture, the v1->v8 provenance map,
and the incremental-experiment workflow.

Public API is re-exported from .main:

    from workload_generation.src import generate_query_batch, write_workload_directory
"""

from .main import *  # noqa: F401,F403
