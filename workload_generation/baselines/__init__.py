"""
Related-work SQL generation baselines, adapted to the Trino/Iceberg lakehouse.

Every baseline exposes a single ``generate_workload(ctx, *, workload_name,
num_queries, ...) -> dict`` entry point that follows the paper's own pipeline
as closely as the lakehouse context allows, and writes the same artefacts as
QueryDock (``q<i>.sql`` + ``generation_report.json``) via
:func:`workload_generation.baselines.common.write_baseline_workload`.

The ``BASELINES`` registry lets the runner scripts dispatch by name.
"""

from workload_generation.baselines import (
    sqlstorm,
    sqlbarber,
    e2etune,
    bootstrapping_lcm,
    sql_factory,
)

BASELINES = {
    "sqlstorm": sqlstorm.generate_workload,
    "sqlbarber": sqlbarber.generate_workload,
    "e2etune": e2etune.generate_workload,
    "bootstrapping_lcm": bootstrapping_lcm.generate_workload,
    "sql_factory": sql_factory.generate_workload,
}

__all__ = [
    "BASELINES",
    "sqlstorm",
    "sqlbarber",
    "e2etune",
    "bootstrapping_lcm",
    "sql_factory",
]
