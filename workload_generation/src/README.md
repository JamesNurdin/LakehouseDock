# workload_generation/src — the consolidated QueryDock generator

One coherent generator (the v8 design) split by **concept**, replacing the
`query_generator_v*.py` chain. Every version was a fork-with-tweaks of the last;
this directory factors the *concepts* out of that lineage so each lives in one
file with one responsibility, and new ideas are added as small **experiments**
rather than whole new copies.

> Module names are snake_case (PEP 8). Rename if you prefer `diversityTracker.py`.

## The pipeline in one breath

```
config ─┐
        ▼
schema → sampling → prompt ──▶ llm ──▶ validation ──▶ diversity_tracker
   ▲         ▲         ▲                                     │
   └─────────┴─────────┴──────── feedback ◀──────────────────┘   (closes the loop)
                         concurrency drives the batch;  report writes the output
                                        main.py wires it all
```

A single query: **sample a shape** (family + add-ons + plan-shape) → **ask the
feedback loop for operator hints** → **sample tables/columns/values** (biased to
under-used ones) → **build the prompt** → **call the LLM** → **EXPLAIN-validate** →
**try to accept** (dedup + novelty caps) → **update the tracker**. The batch runs
many of these through the adaptive concurrency pool until N are accepted.

## Files & responsibilities

| module | responsibility | ported from |
|--------|----------------|-------------|
| `config.py` | every constant + rationale (the only place magic numbers live) | all versions |
| `schema.py` | dataset schema, FK graph, live Trino DDL/column introspection | v1 |
| `sampling.py` | coverage-weighted table selection + predicate value aid | v1 walk, v2 weighting |
| `prompt.py` | families / add-ons / plan-shapes, task+schema text, templates, hint injection | v2, v3, v6, v8 |
| `operator_space.py` | C_phys operator ceiling + lever→operator map (from `resources/`) | v8 (was `utils.py`) |
| `llm.py` | client, retry (+observer), structured `generate_sql` (+token usage), warmup | v1, v2, v9 |
| `concurrency.py` | AIMD controller, saturating pool, retry-observer wiring, progress signal | v6, v9.2, adaptive |
| `validation.py` | EXPLAIN plan, plan signatures, plan DAG, structural n-grams | v3, v72→v8 |
| `diversity_tracker.py` | **schema-usage + structural** memory; acceptance, dedup, caps, coverage/entropy | v2, v3, v8 |
| `feedback.py` | the loop: deficit-hint policy (F-1), reward (F-2), plateau (F-4), gaps (F-6) | v7.x→v8 |
| `pipeline.py` | `generate_query` (single) + `generate_query_batch` (accept loop) | v6, v8 |
| `report.py` | `write_workload_directory` + `generation_report.json` assembly | v6 |
| `main.py` | public API surface (what `lakehouse.py` imports); wires the v8 defaults | all |
| `experiments/` | small override files (v9.x-style) that don't touch the core | — |

## Provenance — why each concept exists, and where it went

**v1 (`query_generator.py`) — grounding.** `load_schema`, `build_relationship_graph`,
`get_relevant_relationships`, `fetch_table_columns(_cached)`, `build_table_ddl_context`,
`build_schema_context`, `make_openai_client`, `call_with_retry`, `generate_sql`,
`warm_up_model`. → **schema.py / llm.py / prompt.py**. *Why:* turn a dataset +
live Trino into a grounded prompt and get one valid query back. Everything else
is diversity pressure layered on top.

**v2 — coverage weighting + prompt vocabulary + dedup.** `DiversityTracker`
(table/edge/column usage), `sample_tables_v2` (coverage-weighted connected walk /
connectivity-guaranteed uniform subset), `build_value_aid` (E2ETune predicate aid
from sampled live values), `PROMPT_VARIANTS` (families), `ADDON_SPECS`,
`build_task_text`, `_dedup_key`/`_skeleton_key` (SQL + skeleton dedup).
→ **diversity_tracker.py / sampling.py / prompt.py**. *Why:* stop the model
re-using the same hub tables/columns and stop emitting near-identical SQL.

**v3 — structural (plan-space) novelty.** `DiversityTrackerV3`, `_plan_signatures`,
`_explain_plan_json`, plan-family cap, min-nearest-neighbour dedup, +plan-shape
line. → **diversity_tracker.py / validation.py / prompt.py**. *Why:* two different
SQL strings can compile to the same physical plan; dedup on the *plan*, not the text.

**v6 — diversity-max generation levers (current open-loop base).** `TEMPERATURE_FLOOR`
(D-1 hot sampling), `FAMILY_WEIGHTS` (D-3 wide/bimodal sizes), rich + exotic add-ons
(D-2), 8 `PLAN_SHAPES` (D-4), `PLAN_SIGNATURE_CAP=3` (D-5), `sample_shape_spec`,
`generate_query_batch`, `write_workload_directory`, `_record_batch_stats`.
→ **config.py / prompt.py / pipeline.py / report.py**. *Why:* spend effort on the
*generation* side (the only lever that raises the motif-vocabulary ceiling).

**v7 → v7.1 → v7.2 — the feedback arc (RETIRED; documented in `feedback.py`).**
multiplicative feedback (collapsed Vendi), additive floor, online lever→motif
attribution, UCB exploration, exotic arms, temperature/table plateau escalation.
*Why kept only as lessons:* every v7.x run regressed vs v6 — reweighting a fixed
lever set can't raise the ceiling. The three surviving lessons (no multiplicative
feedback; steer at the prompt not the weights; direct not blind escalation)
constrain the v8 design and are recorded at the top of `feedback.py`.

**v8 — operator-space-grounded prompt feedback (the design this dir implements).**
`operator_space` (C_phys ceiling + lever map, F-0), named-operator deficit hints
into `build_task_text` (F-1, with softmax sampling + operator pairing F-1b),
Vendi-aligned child-path 3-gram reward (F-2), directed plateau pressure (F-4),
coverage/entropy/discovery instrumentation (F-6), `DiversityTrackerV8`.
→ **feedback.py / operator_space.py / diversity_tracker.py**. *Why:* the deficit
signal reaches the one place that can create a missing operator — the prompt —
naming the specific underused operators instead of reweighting generic add-ons.

**Infra added along the way.** token/validity accounting + `_generate_sql_with_usage`
(v9) → **llm.py / report.py**; continuous saturating pool (v9.2) + AIMD adaptive
concurrency + retry observer + progress bar (latest) → **concurrency.py / llm.py**.

## Keeping the incremental workflow (your v9.x sandbox)

The core exposes **injectable policies** so a new idea is a small override, not a
new copy of the whole generator:

- `DiversityTracker` (schema + structural + acceptance) — subclass to change
  tracking/acceptance.
- `FeedbackPolicy` (in `feedback.py`) — subclass to change *how hints/depth are
  chosen* (this is where v9's hazard-gate curriculum, F-5 hit-rate weighting, etc.
  belong).
- `ConcurrencyController` — subclass/replace to change scheduling.

`pipeline.generate_query_batch(...)` takes `tracker=` and `policy=` arguments
(dependency injection), defaulting to the v8 behaviour. So an experiment is:

```python
# experiments/v9_hazard.py
from ..diversity_tracker import DiversityTracker
from ..feedback import FeedbackPolicy

EXP_MAX_DEPTH = 5          # experiment constants live HERE, namespaced EXP_*

class HazardPolicy(FeedbackPolicy):
    def choose_depth(self, tracker, rng):   # override ONE decision
        ...                                  # v9's validity-Beta hazard gate
```

Run it without touching the core:

```python
from workload_generation.src import pipeline
from workload_generation.src.experiments.v9_hazard import HazardPolicy
pipeline.generate_query_batch(..., policy=HazardPolicy())
```

Rules for experiments: (1) never edit `src/` core files — subclass/inject;
(2) put experiment constants in the experiment file as `EXP_*`, not in `config.py`;
(3) keep the `feedback_enabled=False → == v6` off-switch working so every
experiment has a clean control. Copy `experiments/_template.py` to start.
