"""
query_gen_eval
==============

Related-work SQL query-generation baselines, adapted to the QueryDock
Trino / Iceberg lakehouse context so that they can be compared on equal
footing against the QueryDock generator
(``LakehouseDock/trino_stack/query_generator.py``).

Each baseline lives in :mod:`query_gen_eval.baselines` and re-uses the
existing QueryDock infrastructure as much as possible (schema loading,
DDL introspection, the OpenAI client + retry helpers, and EXPLAIN-based
validation against a live Trino coordinator) so that the *only* thing
that differs between a baseline and QueryDock is the generation pipeline
itself -- exactly what we want to measure.

Every baseline writes the same on-disk artefacts as QueryDock:

  * ``q<i>.sql``               one file per accepted query
  * ``generation_report.json`` run metadata + per-query metaheuristics

The ``generation_report.json`` mirrors the structure produced by
``trino_stack.query_generator.write_workload_directory`` (see the sample
at ``LakehouseDock/Workloads/bigbenchv2/generation_report.json``) and is
enriched with the static SQL "metaheuristics" computed in
:mod:`query_gen_eval.sql_features`.

Papers implemented (see ``README.md`` for the mapping):

  * SQLStorm            -- Schmidt et al., PVLDB 18(11), 2025
  * SQLBarber           -- Lao & Trummer, SIGMOD 2025
  * E2ETune (OLAP gen)  -- Yao et al., PVLDB 18(5), 2025
  * Bootstrapping-LCM   -- Nidd et al., VLDB AIDB Workshop 2025 (DiGiT)
  * SQL-Factory         -- multi-agent large-scale SQL generation
"""

from query_gen_eval.common import (
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
