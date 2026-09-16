# workload_generation — DiverSQL generator + related-work baselines

This package lives at `LakehouseDock/workload_generation/` (alongside `trino_stack`
and `loader`). It contains the DiverSQL generator itself
(`query_generator.py`) and the SQL-workload-generation baselines it is compared against, adapted
to the **Trino / Iceberg lakehouse** context so the comparison is fair: every
baseline reuses the *same* DiverSQL infrastructure (schema loading, live DDL
introspection, the OpenAI client + retry/back-off, and `EXPLAIN`-based
validation against the deployed Trino coordinator). The **only** thing that
differs between a baseline and DiverSQL is the generation pipeline itself.

Each baseline follows its paper's own pipeline as closely as the lakehouse
allows, and writes the **same artefacts as DiverSQL**:

```
<WORKLOAD_ROOT>/<workload_name>/
    q1.sql, q2.sql, ...            # one accepted query per file
    generation_report.json        # run metadata + per-query & workload metaheuristics
```

## Baselines

| module | paper | pipeline |
|--------|-------|-----------------------|
| `baselines/sqlstorm.py` | **SQLStorm** — Schmidt et al., *PVLDB* 18(11), 2025 | 7-prompt suite (P1–P7) + whole-schema `CREATE TABLE` suffix → clean/rewrite (dedup, strip comments, first statement, fixed timestamp) → LLM Trino-compatibility rewrite (their `PF` step) → selection by Trino `EXPLAIN` → low/med/high complexity classification |
| `baselines/sqlbarber.py` | **SQLBarber** — Lao & Trummer, *SIGMOD* 2025 | NL+numeric-spec **template generator** with an LLM **self-correction loop** (judge + repair vs Trino `EXPLAIN`) → **cost-aware instantiation**: profile templates, build a target cost distribution, and a BO-style predicate search to match it; reports Wasserstein distance |
| `baselines/e2etune.py` | **E2ETune** (OLAP gen) — Yao et al., *PVLDB* 18(5), 2025 | 6-component prompt (Task / Schema / Guidance / **Predicate Aid from sampled live values** / Sample queries / Output) → diversity control (random tables+values+samples) → `EXPLAIN` **repair loop** → workload = accepted set |
| `baselines/bootstrapping_lcm.py` | **Bootstrapping-LCM / DiGiT** — Nidd et al., *VLDB AIDB Workshop* 2025 | enumerate **connected FK subschemas** → few-shot `DataBuilder` prompt with **mechanically-generated seed examples** + group-by/order-by bias → validators (dedup + `EXPLAIN`) → **coverage-gap-driven re-biasing** |
| `baselines/sql_factory.py` | **SQL-Factory** — multi-agent generation | **Generation Team** (table-selection weighted by coverage+complexity; high-reasoning generation agent) + **Expansion Team** (low-reasoning seed mutation) + **Management Team** (Critical Agent: `EXPLAIN` + hybrid token/AST/embedding similarity; Management Agent: exploration/exploitation scheduling) |


## Running

Both entry points accept either a live `Lakehouse` release (as in
`launch_lakehouse.ipynb`) or a raw Trino host.

**One baseline:**

```bash
python -m workload_generation.scripts.run_baseline \
    --baseline sqlstorm --schema tpcds \
    --instance lakehouse-a --namespace pgr24james \
    --num-queries 1000 --workload-name sqlstorm_tpcds
```

**Full sweep (all baselines × schemas + `comparison_summary.json`):**

```bash
python -m workload_generation.scripts.run_all \
    --schemas tpcds ssb imdb ldbc_snb_sf1000 bigbenchv2_sf1000 stats_ceb_sf1000 \
    --instance lakehouse-a --namespace pgr24james --num-queries 1000
```


## Layout

```
LakehouseDock/workload_generation/
    __init__.py          # BaselineContext + context builders + write_baseline_workload
    query_generator.py   # the DiverSQL generator (schema sampling, DDL context, LLM generation, workload writer)
    common.py            # shared context: LLM calls, EXPLAIN validate, cost profiling, value sampling, report writer
    sql_features.py      # static SQL metaheuristics (sqlglot or regex fallback)
    baselines/           # the five baselines + BASELINES registry
    scripts/             # run_baseline.py, run_all.py
```


