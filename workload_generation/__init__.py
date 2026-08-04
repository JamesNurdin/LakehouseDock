"""
workload_generation
===================

SQL workload generation for the Trino / Iceberg lakehouse.

Contains the QueryDock generator itself
(:mod:`workload_generation.src`) alongside the related-work
query-generation baselines it is compared against, adapted to the same
lakehouse context so that they can be compared on equal footing.

Each baseline lives in :mod:`workload_generation.baselines` and re-uses the
existing QueryDock infrastructure as much as possible (schema loading,
DDL introspection, the OpenAI client + retry helpers, and EXPLAIN-based
validation against a live Trino coordinator) so that the *only* thing
that differs between a baseline and QueryDock is the generation pipeline
itself -- exactly what we want to measure.

Every baseline writes the same on-disk artefacts as QueryDock:

  * ``q<i>.sql``               one file per accepted query
  * ``generation_report.json`` run metadata + per-query metaheuristics

The ``generation_report.json`` mirrors the structure produced by
``workload_generation.src.report.write_workload_directory`` (see the sample
at ``LakehouseDock/Workloads/bigbenchv2/generation_report.json``) and is
enriched with the static SQL "metaheuristics" computed in
:mod:`workload_generation.sql_features`.

Papers implemented (see ``README.md`` for the mapping):

  * SQLStorm            -- Schmidt et al., PVLDB 18(11), 2025
  * SQLBarber           -- Lao & Trummer, SIGMOD 2025
  * E2ETune (OLAP gen)  -- Yao et al., PVLDB 18(5), 2025
  * Bootstrapping-LCM   -- Nidd et al., VLDB AIDB Workshop 2025 (DiGiT)
  * SQL-Factory         -- multi-agent large-scale SQL generation
"""

from workload_generation.baselines.common import (
    BaselineContext,
    context_from_factories,
    context_from_lakehouse,
    write_baseline_workload,
)

__all__ = [
    "BaselineContext",
    "context_from_factories",
    "context_from_lakehouse",
    "write_baseline_workload",
]
