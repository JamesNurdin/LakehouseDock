# Predictive (uncertainty-aware) baselines

Every baseline consumes the query plans + runs produced by
`load_aligned_plans_and_runs`, trains on log-runtime targets
(`aggregate_query_log_runtime`, i.e. `log(max t_rel_s)`), and is scored back in
runtime space. Each exposes a tiny, uniform API and returns either a Gaussian
predictive distribution or a point/quantile prediction, which the shared
`common/metrics.py` turns into rows across all four workbook sheets.

## The lakehouse feature-gap 

The roster models were written for **Postgres** `EXPLAIN` output — per-operator
actual/estimated tuples, buffer hits/reads, index scans, per-table/column
catalog statistics. In the **Trino/Iceberg lakehouse** those signals do not
exist. Rather than fabricate them, these adapters use only what the lakehouse
plan DAG actually carries:

- operator identity / counts (train-fit vocabulary + `UNK` bucket),
- Trino cost estimates: `outputRowCount`, `outputSizeInBytes`, `cpuCost`,
  `memoryCost`, `networkCost` (log1p-summarised, with missing-flags),
- coarse plan structure (node/edge/fragment counts, remote edges, tree shape).

Each model's docstring states precisely which native features are dropped. The
most important caveat is **Zero-Shot**, whose zero-shot *transfer* property
depends on catalog statistics we don't have: we reproduce its architecture, not
its transferability. Read its numbers accordingly.

## Layout

```
predictive/
├── common/                 shared adapters, metrics, backbones
│   ├── features.py         PlanFeatureAdapter + build_feature_dataset   (plan → standardised vector)
│   ├── graph.py            NodeGraphAdapter + build_graph_dataset        (plan → tree/graph tensors)
│   ├── mlp.py              GaussianMLP + train loop (shared MLP backbone)
│   └── metrics.py          CRPS / coverage / MPIW / Spearman·Pearson / point metrics
│
├── mean_variance_nll/      Gaussian NLL head                 
├── mc_dropout/             MC-Dropout                        
├── deep_ensembles/         Deep Ensembles                    
├── ngboost/                NGBoost (Normal)                  
├── quantile_regression/    multi-quantile MLP (pinball)      
├── conformal/              Conformalised Quantile Regression 
│
├── qppnet/                 plan-structured per-operator net  
├── zero_shot/              plan-graph GNN                   
├── reqo/                   bidirectional tree-GNN + NLL head 
├── nngp/                   analytic NNGP kernel + GP         
│
└── tlstm/                  tree-LSTM heteroscedastic regressor 
```

## Model summary

| Model | Package | Encoder | Predictive form |
|-------|---------|---------|-----------------|
| Mean–Variance NLL | `mean_variance_nll` | shared features | Gaussian |
| MC-Dropout | `mc_dropout` | shared features | Gaussian (MC moments) |
| Deep Ensembles | `deep_ensembles` | shared features | Gaussian (mixture) |
| NGBoost | `ngboost` | shared features | Gaussian | all 4 | `ngboost` |
| Quantile Regression | `quantile_regression` | shared features | quantile grid |
| Conformal Prediction | `conformal` | shared features | calibrated intervals |
| QPPNet | `qppnet` | plan-tree (per-op units) | point | point only | — |
| Zero-Shot Cost Model | `zero_shot` | plan GNN | point | point only | — |
| Reqo | `reqo` | bidirectional tree-GNN | Gaussian |
| NNGP | `nngp` | shared features + NNGP kernel | Gaussian |
| TLSTM (predictive) | `tlstm` | tree-LSTM | Gaussian |

*Sheets: (1) point error, (2) CRPS, (3) interval quality, (4) uncertainty
effectiveness. Tier-1 point models are `n/a` for sheets 2–4 by design.*

## Usage

Two entry points build model-ready data from the loaded plans/runs:

- `build_feature_dataset(...)` → flat standardised feature vectors + targets
  (feature-based models: the six T2 mechanisms + NNGP).
- `build_graph_dataset(...)` → per-plan tree/graph tensors + targets
  (structured models: QPPNet, Zero-Shot, Reqo).

Both fit their adapters on the **training split only** (no test leakage) and
return aligned `train`/`test` arrays plus the kept query ids.

### Gaussian model (feature-based)

```python
from uncertainty_prediction.baselines.predictive.common import (
    build_feature_dataset, evaluate_gaussian_predictions,
)
from uncertainty_prediction.baselines.predictive.mean_variance_nll import MeanVarianceNLL

data = build_feature_dataset(plans_by_query, runs_by_query, train_qids, test_qids, xcol=XCOL)

model = MeanVarianceNLL(in_dim=data["feature_dim"], device=device, seed=42)
model.fit(data["X_train"], data["y_train_log"], num_epochs=200)

pred = model.predict_gaussian(data["X_test"])          # {mu_log, sigma_log}
metrics = evaluate_gaussian_predictions(pred["mu_log"], pred["sigma_log"], data["y_test_log"])
```

`NGBoostBaseline`, `NNGPBaseline` and (via `.predict_gaussian`) `MCDropout`,
`DeepEnsemble` follow the identical pattern.

### Quantile / conformal model

```python
from uncertainty_prediction.baselines.predictive.common import evaluate_quantile_predictions, override_with_calibrated_intervals
from uncertainty_prediction.baselines.predictive.conformal import ConformalPrediction

cp = ConformalPrediction(in_dim=data["feature_dim"], cal_frac=0.3, device=device, seed=42)
cp.fit(data["X_train"], data["y_train_log"], num_epochs=200)

Q = cp.predict_quantiles(data["X_test"])
m = evaluate_quantile_predictions(cp.qlevels, Q, data["y_test_log"])           # point/CRPS/unc from grid
m = override_with_calibrated_intervals(m, cp.predict_calibrated_intervals(data["X_test"]), data["y_test_log"])
```

### Structured model (graph/tree)

```python
from uncertainty_prediction.baselines.predictive.common import build_graph_dataset, evaluate_point_predictions
from uncertainty_prediction.baselines.predictive.qppnet import QPPNetBaseline

gdata = build_graph_dataset(plans_by_query, runs_by_query, train_qids, test_qids, xcol=XCOL)

qpp = QPPNetBaseline(num_ops=gdata["num_ops"], cont_dim=gdata["cont_dim"], device=device, seed=42)
qpp.fit(gdata["train_graphs"], gdata["y_train_log"], num_epochs=100)

mu_log = qpp.predict_point_log(gdata["test_graphs"])
metrics = evaluate_point_predictions(np.exp(mu_log), np.exp(gdata["y_test_log"]))
```

`ReqoBaseline` uses the same graph data but returns `.predict_gaussian(...)`.

## Notebooks

Runnable end-to-end examples live one level up in `uncertainty_prediction/`:

- `test_predictive_baseline_tlstm.ipynb` — pre-existing reference.
- `test_predictive_baseline_mlp_heads.ipynb` — Mean–Variance NLL, MC-Dropout, Deep Ensembles.
- `test_predictive_baseline_classical.ipynb` — NGBoost, Quantile Regression, Conformal.
- `test_predictive_baseline_named.ipynb` — QPPNet, Zero-Shot, Reqo, NNGP.

## Metrics (`common/metrics.py`)

Everything is derived in **log-runtime space** and reported in the units each
sheet expects:

- **Point error** — MAE/RMSE (log & runtime), QError percentiles.
- **CRPS** — closed-form Gaussian CRPS; quantile models use
  `2 · mean(pinball)` over the grid.
- **Interval quality** — central-interval coverage at 50/90/99 and MPIW at 90%
  (runtime space). Conformal reports calibrated coverage/MPIW.
- **Uncertainty effectiveness** — Spearman (primary) and Pearson correlation of
  predicted uncertainty against realised absolute error.

Excel helpers `print_metric_headers_for_excel` / `print_metrics_for_excel` emit
tab-separated header/value rows to paste into the workbook.

## Reproducibility & notes

- All models take a `seed`; call `set_seed(42)` (from `uncertainty_prediction.src`)
  once at the top of a notebook.
- Adapters standardise on the training split only.
- Structured models (QPPNet/Zero-Shot/Reqo) train one plan at a time (faithful
  to tree structure, un-batched) — fine for a few hundred queries; add batching
  before scaling to thousands.
- NNGP is an exact GP: O(n²) kernel + n×n Cholesky in train size; trivial at the
  current split, worth noting for larger ones. Tune `noise` if coverage drifts.
- `ngboost` is the only extra dependency (`pip install ngboost`), imported
  lazily so the other baselines work without it.
