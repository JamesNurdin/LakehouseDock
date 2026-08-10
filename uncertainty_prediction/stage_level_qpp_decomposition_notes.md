# Stage-level decomposition for QPP — feasibility notes (not yet implemented)

Written 2026-08-09 from a conversation exploring whether we can get more
mileage out of Trino query traces by predicting execution time at a finer
granularity than "whole query" and composing the pieces, instead of (or in
addition to) the current whole-query targets in `targets.py`. This is an idea
for later — nothing here has been built. It records what was verified against
real data so a future session doesn't have to re-derive it.

## Where this sits relative to what already exists

- Whole-query targets today (`src/targets.py`): per-query log-runtime
  (`logT_mean/logT_std`) and an RBF-basis fit of the resource curve
  (`cpu_cores` vs `t_rel_s`) from `Parsed_Results`. One label per query (or
  per run, via `build_run_targets`).
- `baselines/predictive/qppnet/model.py` already implements the
  Marcus & Papaemmanouil (2019) architecture: one small MLP "unit" per
  operator type, composed bottom-up through the plan tree
  (`_OperatorUnit`, `_QPPNet.forward`). **But** it only supervises the final
  scalar query runtime — there is no intermediate per-operator ground truth
  feeding the loss, because (as below) Trino doesn't hand you clean
  per-operator actual times the way Postgres does (which is what the
  original QPPNet paper relies on). This doc is essentially about closing
  that gap at the stage level rather than the operator level.
- The plan DAG fed to all structured encoders (`build_trino_dag` in
  `loader/parser.py`, consumed via `iter_trino_dags`/`load_plans_by_query` in
  `loader/load.py`, then `trinoGraphQueryEncoder.py` /
  `trinoGraphGINQueryEncoder.py`) is parsed **only** from each query's
  `*_explain.json` — the static, pre-execution plan. Every node in that dag
  dict already carries a `fragment` id (`nodes[node_id]["fragment"]`,
  `fragment_roots` in `build_trino_dag`). That fragment id is the load-bearing
  fact behind the recommendation below.

## What's actually in the raw files (verified against real data)

Source: `Results/` (symlink to `/mnt/lakehouse-raw-results`) →
`tpcds/lakehouse-a/<run_id>/queries/q<N>_001.json` (actual `QueryInfo` dump,
Trino 471) and the sibling `q<N>_001_explain.json` (static JSON-format plan).
Confirmed both exist for the run_ids already in `config.py`/`new_config.py`
(e.g. `tpcds_500`, run `20260222-191819Z` has 450 queries × 2 files). This is
a different tree from `Parsed_Results` (which only has resource-curve
parquets + a `_meta.json` with no timing) — **nothing in the current loader
touches the raw actual JSON's stage tree**; only the `_explain.json` half is
consumed today.

Verified on `q1_001.json` / `q1_001_explain.json`
(`20260124-100551Z`, one query, 5 repeated runs available for `tpcds_500`):

- **Fragment id ↔ stage id is a direct match.** `_explain.json` is keyed
  `"0".."10"`; the actual JSON's `outputStage`/`subStages` tree has stage ids
  `<trinoQueryId>.0` .. `.10` — same numbering, same tree shape (confirmed by
  walking both and comparing `RemoteSource.descriptor.sourceFragmentIds`
  against `subStages` nesting). Plan node ids also match exactly:
  `RemoteSource id=1867` in fragment 0 ↔ `ExchangeOperator planNodeId="1867"`
  in the actual stage `.0`'s `operatorSummaries`.
- **Stage-level actual timing is real wall-clock**, not an artifact of
  parallelism: each stage's `tasks[]` list has per-task
  `stats.firstStartTime` / `stats.lastEndTime` (ISO timestamps). Taking
  `min(firstStartTime)` / `max(lastEndTime)` across a stage's tasks gives a
  genuine `[start, end]` window for that stage. For q1: 11 stages, e.g. stage
  `.3` ran `10:05:55.066Z → 10:06:21.387Z` (26.3s) across 4 tasks.
- **Pipeline-level timing is also real** (`pipelines[].firstStartTime/
  lastStartTime/lastEndTime` per task) and finer than stage — q1 has 28
  distinct `(stageId, pipelineId)` pairs vs. 11 stages — but pipelines are
  **not visible in the static explain plan at all**. They're a runtime
  scheduling artifact assigned when the query actually executes, so a model
  meant to predict *before* running the query has no way to know its
  pipeline decomposition up front. This is the main reason pipeline-level
  was set aside in favor of stage-level, on top of the motif argument below.
- **Operator-level timing (`operatorSummaries[].addInputWall/getOutputWall/
  finishWall`) is summed across every concurrent driver in that pipeline —
  not a wall-clock duration.** Confirmed example: stage `.3` pipeline 2 (17
  drivers) shows `ScanFilterAndProjectOperator.getOutputWall = 1.87m` inside
  a pipeline whose real window was 25.5s. Using these as labels directly
  would require dividing out concurrency, and the JSON doesn't record how
  many drivers were *simultaneously* active vs. queued — only the total
  count. Additionally, `pipelines[].drivers` is an **empty list** in every
  captured file (confirmed `pruned: false` in `q1_001.json`, so this isn't
  post-hoc pruning — Trino simply never serializes per-driver detail into
  the retained `QueryInfo`). There is no per-operator-instance timestamp
  anywhere in this data.
  - If operator-level ground truth is ever wanted, the path is Trino's
    Event Listener SPI (`io.trino.spi.eventlistener.EventListener`,
    specifically `splitCompleted(SplitCompletedEvent)` — fires once per
    completed split with its own, non-aggregated timing). Not currently
    configured on this cluster (no `event-listener.properties` / nothing in
    `values.yaml`). Bundled `http-event-listener` plugin is the fastest way
    to try it; see `https://trino.io/docs/current/develop/event-listener.html`.
    Out of scope unless stage-level turns out insufficient.
- **A single logical join node fans out into two physical operators in two
  different, concurrently-running pipelines** (build side + probe side): 26
  of q1's 49 plan nodes do this (e.g. plan node `646` → `HashBuilderOperator`
  in pipeline 1 and `LookupJoinOperator` in pipeline 4). This is exactly the
  kind of complication that pipeline-granularity decomposition would have to
  model explicitly (a "cost" that isn't attributable to one unit because it's
  split across concurrent siblings). Stage granularity sidesteps it — the
  build and probe pipelines are part of the *same* stage/fragment, so their
  concurrency is internal to the unit rather than a cross-unit modeling
  problem.
- **CBO cost estimates in the explain plan are unreliable and should stay
  excluded**, consistent with what `baselines/predictive/README.md` already
  does (it log1p-summarises them with missing-flags rather than trusting
  them raw). Measured `cpuCost`/`outputRowCount` NaN-or-missing rate across
  6 queries: q1 ~51%, q10 ~74%, q11 ~80%, q12 ~74%, q13 ~59%, q14 ~68%. Only
  leaf table scans (`ScanFilter`/`ScanFilterProject`/`TableScan`) carry real
  numbers from table statistics; everything downstream of a join or
  aggregate degrades to `NaN`. Use operator type + plan shape + leaf-scan
  cardinalities as structural features; don't lean on the cost fields.
- **Stage windows overlap heavily — aggregation cannot be summation.** In
  q1, the dependency chain `.0 ← .1 ← .2 ← .3` has each stage spanning
  ~26–29s, almost entirely overlapping, while total `elapsedTime` is only
  ~30s. Summing predicted per-stage durations along that chain would
  overestimate by roughly 4x. Whatever combines per-stage predictions into a
  final wall-time number has to be a **learned composition function**, not a
  formula — this is the same reason `QPPNetBaseline` composes bottom-up with
  a neural unit per node rather than adding up costs.

## Recommendation: decompose at stage/fragment granularity

Reasoning, in order of how load-bearing each point is:

1. **Fragment ids are known before execution** — they're already a field on
   every parsed plan node (`nodes[node_id]["fragment"]` from
   `build_trino_dag`). Pipeline ids are not knowable pre-execution at all.
   For a *predictive* (pre-execution) model, this alone rules out pipeline
   as the primary decomposition unit.
2. **Stage-level actual durations are clean real timestamps** — no
   driver-parallelism aggregation problem to solve, unlike operator level.
3. **Stage boundaries are exchange boundaries** — they separate coherent,
   colocated computation (a scan+filter+partial-agg fragment, a hash-build
   fragment, a probe+aggregate+output fragment). These recur across
   different queries as a stable vocabulary of "motifs" in the same way
   individual operator types do, but without the build/probe fan-out
   splitting a single unit's cost across concurrent siblings the way a raw
   operator- or pipeline-level decomposition would.
4. Trade-off to keep in mind: pipeline granularity gives ~2.5x more labeled
   units per query than stage (28 vs 11 in q1) and operator gives ~7x (80).
   Stage is the conservative middle ground — a large multiplier over
   "1 label per whole query" while keeping every unit pre-execution-knowable
   and cleanly timed. If stage-level turns out to be data-starved in
   practice, pipeline is the next thing to try, with the build/probe fan-out
   handled as an explicit structural feature (flag a node as
   build-side/probe-side) rather than ignored.

## Concrete gap to build, next time this is picked up

Nothing here exists in the codebase yet. In order:

1. **New loader function**, parallel to `iter_trino_dags`/`build_trino_dag`
   in `loader/parser.py` / `loader/load.py`, that reads the *actual* query
   JSON (not `_explain.json`) from the raw `Results/` tree and walks
   `outputStage`/`subStages` recursively, extracting per stage:
   `stageId` suffix (→ fragment id, direct integer match, no fuzzy join
   needed), `min(tasks[].stats.firstStartTime)`,
   `max(tasks[].stats.endTime)`, `numTasks`, and optionally
   `stageStats.totalCpuTime`/`totalScheduledTime`/`totalBlockedTime` as
   auxiliary (not primary) features — `totalBlockedTime` in particular might
   help a learned combinator distinguish "waiting on another stage" from
   "own compute," rather than inferring it purely from overlapping
   timestamps.
2. **Target construction**: a per-fragment scalar duration (log-space,
   analogous to `logT_mean/logT_std` in `targets.py` but keyed by
   `(query_run_id, fragment_id)` instead of just `query_run_id`), built from
   repeated runs the same way `build_run_targets`/`build_query_targets` do
   today. `RUN_IDS` in `config.py`/`new_config.py` already give 3–5 repeats
   per collection to estimate this — worth checking empirically how much
   per-stage timing varies run-to-run (contention/caching) before investing
   further, since that variance sets a ceiling on achievable accuracy.
3. **Model**: fork `baselines/predictive/qppnet/model.py`'s
   `_OperatorUnit`/`_QPPNet` pattern, but make the composed unit a
   stage/fragment rather than a single operator — features become an
   aggregate over the operators inside that fragment (operator-type
   histogram, fragment depth/fan-in/out, leaf-scan cardinality if present)
   instead of one-node-one-unit. Compose bottom-up along the fragment DAG
   (`fragment_roots` + remote edges, already computed by `build_trino_dag`)
   with a learned combinator, trained with a **multi-task loss**: per-stage
   auxiliary targets (from step 2, now actually available — the thing the
   current `QPPNetBaseline` lacks) plus the final whole-query target. This
   is the actual fix for the gap noted in that baseline's docstring.
4. **Small thing to watch**: some stages are very short (dimension-table
   scans finishing in <1s in q1, e.g. `.4`/`.5`/`.10`). Fit targets in
   log-space with a floor, the same way `targets.py` already does
   (`log(T + eps)`), to avoid near-zero-duration instability dominating the
   loss.

## Open questions for whoever picks this up

- How much does per-stage timing vary across the existing repeated runs
  (same query, same `RUN_IDS`)? Cheap to check before building anything else
  — it bounds the whole approach.
- Is a scalar per-stage duration enough, or is a per-stage resource-curve
  (reusing the `RBFTauBasis` machinery from `basis.py`/`targets.py`, just
  scoped to one fragment's task windows) worth the extra complexity? Start
  with the scalar; only go to curves if the scalar version shows the
  decomposition is paying off.
- Whether `totalBlockedTime` per stage should be a feature, a secondary
  target, or left out — it conflates genuine cross-stage data dependency
  with scheduler/resource contention, so it's not a clean signal on its own,
  but it might still help the combinator learn overlap patterns rather than
  discovering them purely from timestamp arithmetic.
