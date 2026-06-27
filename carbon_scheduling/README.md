# carbon_scheduling

**Carbon-aware scheduling** of lakehouse workloads — deciding *when* work runs so that it lands
on cleaner electricity.

## What this is

The research layer on top of LakehouseDock's deploy-and-test loop. Instead of running query
workloads as soon as they arrive, this component shifts them in time according to the carbon
intensity of the electricity grid, aiming to reduce the emissions associated with running the
[`Workloads/`](../Workloads/) against the [`trino_stack/`](../trino_stack/) lakehouse.

It uses forecasts from [`uncertainty_prediction/`](../uncertainty_prediction/) to plan ahead
under uncertainty, rather than reacting only to the current grid state.

<!-- TODO: confirm the carbon intensity data source (e.g. a grid carbon-intensity API /
     historical dataset) and the scheduling strategy implemented. -->

## Contents

<!-- TODO: describe the actual files here. For example:
| File / dir | Purpose |
| --- | --- |
| ...        | Scheduler implementation |
| ...        | Carbon-intensity data ingestion |
| ...        | Scheduling policy / strategy definitions |
| ...        | Evaluation / results |
-->

## Usage

```bash
# TODO: replace with the real command(s), e.g.:
# python carbon_scheduling/schedule.py --policy <name> --forecast <path>
```

## How it fits together

```
uncertainty_prediction  ->  carbon_scheduling  ->  Workloads (dispatched at chosen times)
profile_cluster         ->  carbon_scheduling      (feedback on cost / usage)
```

## Role in LakehouseDock

Optional research component. The core platform works without it; enable it to study
carbon-aware execution of lakehouse query workloads.
