# workload_generation — DiverSQL generator + related-work SQL generation baselines

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

| module | paper | pipeline (as adapted) |
|--------|-------|-----------------------|
| `baselines/sqlstorm.py` | **SQLStorm** — Schmidt et al., *PVLDB* 18(11), 2025 | 7-prompt suite (P1–P7) + whole-schema `CREATE TABLE` suffix → clean/rewrite (dedup, strip comments, first statement, fixed timestamp) → LLM Trino-compatibility rewrite (their `PF` step) → selection by Trino `EXPLAIN` → low/med/high complexity classification |
| `baselines/sqlbarber.py` | **SQLBarber** — Lao & Trummer, *SIGMOD* 2025 | NL+numeric-spec **template generator** with an LLM **self-correction loop** (judge + repair vs Trino `EXPLAIN`) → **cost-aware instantiation**: profile templates, build a target cost distribution, and a BO-style predicate search to match it; reports Wasserstein distance |
| `baselines/e2etune.py` | **E2ETune** (OLAP gen) — Yao et al., *PVLDB* 18(5), 2025 | 6-component prompt (Task / Schema / Guidance / **Predicate Aid from sampled live values** / Sample queries / Output) → diversity control (random tables+values+samples) → `EXPLAIN` **repair loop** → workload = accepted set |
| `baselines/bootstrapping_lcm.py` | **Bootstrapping-LCM / DiGiT** — Nidd et al., *VLDB AIDB Workshop* 2025 | enumerate **connected FK subschemas** → few-shot `DataBuilder` prompt with **mechanically-generated seed examples** + group-by/order-by bias → validators (dedup + `EXPLAIN`) → **coverage-gap-driven re-biasing** |
| `baselines/sql_factory.py` | **SQL-Factory** — multi-agent generation | **Generation Team** (table-selection weighted by coverage+complexity; high-reasoning generation agent) + **Expansion Team** (low-reasoning seed mutation) + **Management Team** (Critical Agent: `EXPLAIN` + hybrid token/AST/embedding similarity; Management Agent: exploration/exploitation scheduling) |

DiverSQL itself is *not* re-implemented here — it is the existing
`Lakehouse.generate_workload(...)` and serves as the reference method.

## Metaheuristics (`generation_report.json`)

Mirrors the DiverSQL report at
`LakehouseDock/Workloads/bigbenchv2/generation_report.json` and adds, via
`sql_features.py`, static (no-execution) **metaheuristics** for a fair
cross-generator comparison:

* **per query** (`queries[i].metaheuristics`): #tables, #joins (+ join types),
  #aggregations, #group-by/order-by/having/where, #predicates, #subqueries,
  #CTEs, #window functions, #set operations, #distinct, #CASE, recursion,
  query length, and SQLStorm-style low/med/high **complexity**.
* **per workload** (`workload_metaheuristics`): min/max/mean/median
  distributions of every feature (the stats E2ETune reports), the SQLStorm
  complexity mix, table-usage entropy, unique-table-set and unique-skeleton
  ratios (structural-diversity proxies), and schema table coverage.
* **per pipeline** (`pipeline`): the baseline-specific run summary — prompt
  suite & yields (SQLStorm), self-correction attempts + Wasserstein alignment
  (SQLBarber), diversity/repair counts (E2ETune), subschema + coverage tables
  (DiGiT), agent schedule + rejection counts (SQL-Factory).

`sql_features.py` uses `sqlglot` for a real parse when installed and falls back
to a regex/keyword tokeniser otherwise, so reports can also be recomputed
offline over an existing workload directory.

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

**From a notebook (mirrors `lh.generate_workload`):**

```python
from trino_stack.lakehouse import Lakehouse
from workload_generation import context_from_lakehouse
from workload_generation.baselines import sqlbarber

lh  = Lakehouse.from_release(instance_name="lakehouse-a", namespace="pgr24james")
ctx = context_from_lakehouse(lh, schema="tpcds", reasoning="high")
report = sqlbarber.generate_workload(ctx, workload_name="sqlbarber_tpcds", num_queries=1000)
```

Per-baseline knobs (e.g. `--extra '{"rewrite_pass": false}'` for SQLStorm, or
`specs=` / `cost_metric=` for SQLBarber) are documented in each module's
`generate_workload` signature.

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

## Notes / honest limitations

* Validation is single-engine (Trino `EXPLAIN`) — the same signal DiverSQL
  uses. SQLStorm's original multi-engine parse-≥2/exec-≥1 rule is reduced to
  this single deployed engine.
* SQLBarber's Bayesian Optimizer is approximated by random-restart hill
  climbing over predicate assignments; the target cost distribution defaults to
  log-spaced over the profiled range (pass `target_costs=` to supply a
  Redset/Snowset-derived distribution). Cost = Trino optimizer estimate from
  `EXPLAIN (FORMAT JSON)`.
* SQL-Factory's "powerful vs lightweight model" split is approximated with
  reasoning-effort (`high` vs `low`) on the single deployed model; the
  embedding term of its hybrid similarity falls back to a token-shingle Jaccard
  when no embedding model is available (token + AST terms are exact).
```
