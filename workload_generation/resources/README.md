# workload_generation/resources

Two curated, version-471 reference tables that scope the **operator space** the
query generator targets. Both are static (no learned/probed mapping): the
operator ceiling is enumerated from Trino source, and the lever→operator map is
grounded in SQL relational semantics (the operator each construct is *required*
to produce), not empirical observation.

## `operators_ground_truth.csv` — the operator ceiling (C_phys)

Every operator name Trino can render in an `EXPLAIN` plan, i.e. every possible
value of `op["name"]` as read by `loader.parser.build_trino_dag` and scored by
the plan-graph diversity metrics.

**Provenance:** rendered names are the string literals emitted by the visitor
methods in Trino's
`core/trino-main/.../sql/planner/planprinter/PlanPrinter.java`; the backing
classes are the `*Node` types in
`core/trino-main/.../sql/planner/plan/`. Pinned to Trino `master` as fetched
2026-07-30 — re-check on Trino upgrade.

| column | meaning |
|--------|---------|
| `rendered_name` | exact name in EXPLAIN output (what metrics see) |
| `logical_operator` | normalized operator with cost/parallelism decorations stripped (e.g. `TopNPartial`→`TopN`, `ScanFilterProject`→`Scan`) |
| `plan_node_class` | backing `PlanNode` subclass |
| `category` | grouping (join / aggregation / window / set / subquery / sort / limit / source / exchange / dml / special) |
| `is_trivial` | 1 if plumbing/surface artifact — matches `query_generator_v72.TRIVIAL_OPERATORS`; excluded from structural motifs |
| `read_reachable` | 1 if reachable from read-only analytical SQL (0 = DML/write/EXPLAIN-only) |
| `iceberg_reachable` | 1 if reachable on the Iceberg connector (0 = e.g. IndexJoin/IndexSource) |
| `notes` | free text |

The **honest coverage denominator** for a read workload on Iceberg is the rows
where `read_reachable=1 AND iceberg_reachable=1`. Feed that set as
`expected_operator_types` to `structural_diversity_summary(...)` (currently
passed `None`) to get a real `operator_type_coverage`.

## `lever_operator_map.csv` — prompt levers → operators

The steering table consumed at prompt-construction time. Each row is a SQL
construct the LLM can be instructed to emit, plus the operator it reliably
produces. Only Tier 1 (semantic guarantee) and Tier 2 (deterministic rewrite
rule) constructs are included — the cost/stats-dependent physical decorations
are deliberately excluded because they are not a reliable function of syntax.

| column | meaning |
|--------|---------|
| `lever_id` | stable id |
| `target_operator` | `rendered_name` (from the ground-truth table) this lever steers toward |
| `secondary_operators` | other operators it typically also introduces |
| `tier` | 1 = semantic guarantee; 2 = deterministic rewrite rule |
| `reliability` | `guaranteed` or `conditional` (e.g. correlated subqueries may decorrelate) |
| `category` | construct family |
| `sql_construct` | the SQL surface form |
| `prompt_hint` | imperative instruction to inject into the task text |
| `example_snippet` | minimal non-degenerate exemplar (also usable as few-shot) |
| `non_degenerate_note` | how to instantiate so the optimizer does not eliminate the operator |

**Reliability caveat:** the map holds *given non-degenerate instantiation*. The
optimizer eliminates provably-redundant operators (`WHERE 1=1`→no Filter,
`SELECT DISTINCT pk`→no dedup). The `non_degenerate_note` column states how to
avoid that per lever. Use `EXPLAIN` only as a one-time version-drift audit, not
as the mapping mechanism.
