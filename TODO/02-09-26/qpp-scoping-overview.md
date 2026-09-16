# QPP Problem Scoping: Supervisor Feedback and Plan

## Notes

### Context: MSCN unbounded-head update (sent prior to the thread)

The MSCN sigmoid head normalised predictions to the [min, max] runtime range observed
during training. At n = 5 this collapsed predictions to a near-constant, evidenced by
Spearman around 0.1. Dataset instances that looked strong at n = 5 and n = 10 had narrow
test-set runtime distributions, so Log MAE was good while multiplicative error was poor.
Runtime binding was toggled off on the grounds that the implementation originates from
cardinality estimation and that runtime prediction models are typically unbounded.
Retraining over five seeds left full-training performance essentially unchanged, which is
consistent with the change only affecting small-n regimes. A mean-only predictor was
tested across the whole dataset and performed considerably worse.

### Richard, 10:30

The point is independent of the model. Taking the mean runtime of some training datasets
as the prediction beats all trained models on the aggregate test set under Log MAE, which
implies multiple constant values outperform any QPP model. Comparison drawn to classical
ML problems that cannot beat a majority-class predictor, indicating either the problem is
un-learnable or current approaches are poor. Noted that a trained model should learn a good
constant if one exists. Also noted that no prior work appears to have pointed this out.

### James, 11:08

Agreed, and proposed inspecting individual test-split distributions. The desired outcome is
that the datasets have very different runtime distributions and that no large centroid of
the entire set exists.

### Lauritz, 11:59

Two concerns raised.

- Problem setting. With only a few training queries, the mean works well for several
  generation approaches, and QPP models eventually overtake it but not by much. Questions
  whether anyone would generate large synthetic workloads and run them on a production
  lakehouse for a marginal prediction gain.
- Realism of the setting. Individual generated query sets are relatively homogeneous, but
  the pooled test set drawn from multiple generators is diverse again. Open question whether
  this constructs an artificially diverse test workload. If the overall workload is diverse
  it is probably not very learnable, and if it were not diverse then real workload queries
  would likely serve better than any generated ones.

### James, 12:46

Agreed the wider issue is framing. Results are positive for most instances, so the problem
is one of scoping when and why to train QPP models for out-of-distribution workloads. The
current position leans on generated workloads being the best training source in general,
which is not true when historical executed queries exist. Generation makes sense without
that history, such as new deployments or schema change, but a stronger argument is needed.
Committed to a problem statement and scoping overview for the following week.

### Lauritz, 14:19 (two additional thoughts)

1. Accepting that generation makes sense without history, the key question is whether QPP
   can or should be used at all in that situation, or whether it only becomes reliable once
   many queries have been seen, possibly many queries of the actual workload.
2. Even where generation is useful for absolute cold starts, real queries should be used
   for training as soon as they are executed, and real queries should probably drive how
   further queries are generated if generation is still needed, balancing exploration of
   the whole possible query space against exploitation of shared characteristics identified
   among the real queries.

### James, 14:56

Acknowledged, to be kept in mind during planning.

## Plan

### A. Diagnostics on existing results

No new generation or execution runs required.

1. Decompose Log MAE per test split rather than over the aggregate, and establish whether
   the constant predictor wins on every split or only after pooling. A win only in
   aggregate indicates a mixture artefact, in which case the fix is in reporting rather
   than modelling.
   ✅ Done — see `test_set_distribution_analysis.ipynb` §4. Result did not match the
   mixture-artefact hypothesis: on the current offline sweep, `mean` never wins pooled
   *or* per-split, at any training-set size (0/63 checkpoints scanned); flagged as needing
   reconciliation with whichever sweep/stamp produced the original "mean beats everything"
   observation.
2. Plot log-runtime distributions per source dataset and per generator, and quantify the
   separation between modes. This directly tests whether a large centroid of the entire set
   exists.
   ✅ Done for the held-out test-set portion only (see `test_set_distribution_analysis.ipynb`
   §2) — training-set distributions not covered (out of scope for this test-set-only pass).
3. Report the constant baseline across the full metric suite rather than Log MAE alone.
   The expectation, following the MSCN clamping diagnosis, is competitive Log MAE alongside
   near-zero rank correlation and poor tail multiplicative error.
   ✅ Done — see `test_set_distribution_analysis.ipynb` §4. Spearman ≈ 0 as expected, but Log
   MAE was *not* competitive either in this sweep (mean's best rank is 5th of 10 models) —
   see the item-1 note above.
4. Quantify the margin and the crossover point at which trained models overtake the
   constant, as a function of training-set size.

### B. Realism and learnability of the test setting

5. Compute plan-graph Vendi on the pooled held-out test set and on each generator's own
   workload, and confirm whether the pooled set is more diverse than any constituent.
   ✅ Done for the held-out-test-vs-held-out-test comparison (see
   `test_set_distribution_analysis.ipynb` §3, revised in §3b) — the naive full-size
   comparison shows pooled test-set Vendi (77.45) beating every individual leg (max 50.40,
   DiverSQL), but this is substantially a sample-size artifact: the pooled set is ~7x any
   single leg's size, and Vendi score is not sample-size-invariant at these n (rarefaction
   check: neither the pooled nor DiverSQL's own curve has flattened out yet). Controlled
   for size (pooled subsampled to n=190, matching a typical leg), pooled Vendi drops to
   43.3 ± 1.9 — *below* DiverSQL's own actual score (50.4) and above only the other six,
   more homogeneous generators. Revised conclusion: pooling does not manufacture more
   diversity than the single most diverse generator once sample size is controlled for;
   it only exceeds the weaker/more homogeneous generators. Not compared against each
   generator's full training workload (would mix train- and test-set questions, out of
   scope for this test-set-only pass).
6. Compare the pooled workload's diversity and runtime profile against real corpora
   (Redset, Snowset, SQLShare, Public BI, BEAVER) to establish whether it has any
   production analogue.
7. Test whether higher training-workload diversity actually degrades downstream prediction
   quality at matched training size. This is the only item that can invalidate the
   generation objective rather than the evaluation, so it takes priority within this group.

### C. Cost accounting

8. Place generation cost and prediction gain on the same axis, including the cluster time
   required to execute generated queries for labelling. Without this the marginal-gain
   question cannot be answered.

### D. Problem statement and scoping document

9. Define the regime axes: volume of observed real queries, presence of drift such as new
   deployment or schema change, and whether the target workload is in or out of
   distribution relative to history. State the recommended training data source per regime.
10. Narrow the claim from generated workloads being generally preferable to generation being
    appropriate where history is absent or invalidated, with value decaying as real queries
    accumulate.
11. Decide whether QPP output at genuine cold start should be a point estimate or a
    calibrated interval with abstention under high plan novelty. The n = 5 results suggest a
    point estimate carries little information in that regime.
12. State explicitly what is out of scope for the current work and why, so the boundary is
    drawn deliberately rather than by omission.

### E. To work towards (Lauritz, additional thought 2)

Continual training on real queries and real-query-conditioned generation are a separate
system rather than a revision to the current work. Recorded here as a direction, not as
current tasks.

- Continual training. An incremental training loop over queries as they execute, a
  retraining trigger, and an evaluation protocol over time rather than over a fixed split.
- Conditioned generation. A mechanism that seeds generation from observed real queries,
  with a tunable budget between exploration of the plan space and exploitation of
  characteristics shared among real queries. The existing diversity tracker implements the
  exploration side, so the conditioning mechanism and the budget parameter are the new
  components.
- Drift evaluation. Training on history up to a schema or workload shift and testing after
  it, since without a drift scenario there is no reason to spend budget on exploration.

A cheap slice of this is available if a real query corpus with runtimes on the cluster can
be obtained: a warm-start sweep seeding with N real queries and comparing generated
augmentation against a real-only control at each N. This yields the crossover curve that
answers the marginal-gain question without building the conditioning mechanism or the drift
scenario. If no such corpus is available, corpus acquisition alone is a multi-week task and
the honest position is to scope the whole direction out for now.

### Sequencing

Group A first, since the diagnostics could change how everything downstream is interpreted.
Group B next, with item 7 prioritised. Group C alongside B. Group D once A to C have
returned results, so the scoping rests on evidence rather than assumption. Group E is a
direction to raise for prioritisation rather than work to schedule.

### To raise at the meeting

Whether to scope the additional-thought-2 direction out entirely for now, or to take the
warm-start slice, given that it is the difference between a reporting and framing revision
and a new system.
