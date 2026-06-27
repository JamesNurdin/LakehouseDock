import numpy as np
import torch
from torch.utils.data import dataset

from uncertainty_prediction.baselines.deterministic.mscn.util import (
    get_all_operator_names,
    get_all_edge_types,
    get_set_encoding,
    encode_plan_nodes_as_samples,
    encode_plan_nodes_as_predicates,
    encode_plan_edges_as_joins,
    normalize_labels,
)


def runtime_from_run_df(df, xcol="t_rel_s"):
    """
    Infer one run's runtime from the trace dataframe.

    Assumes xcol is relative time and the runtime is the maximum observed xcol.
    """
    return float(df[xcol].max())


def aggregate_query_runtime(run_dfs, xcol="t_rel_s", mode="mean"):
    """
    Aggregate multiple observed runtimes for the same query into one scalar target.
    """
    runtimes = [runtime_from_run_df(df, xcol=xcol) for df in run_dfs]
    if len(runtimes) == 0:
        raise ValueError("No runs available to aggregate runtime.")

    if mode == "mean":
        return float(np.mean(runtimes))
    if mode == "median":
        return float(np.median(runtimes))
    if mode == "min":
        return float(np.min(runtimes))
    if mode == "max":
        return float(np.max(runtimes))

    raise ValueError(f"Unknown runtime aggregation mode: {mode}")


def encode_queries_from_plans(
    plans_by_query,
    runs_by_query,
    qids,
    op2vec,
    edge2vec,
    *,
    xcol="t_rel_s",
    runtime_mode="mean",
):
    """
    Encode a set of query plans into MSCN-style sets:
      - samples     := node-level structural tokens
      - predicates  := node-level detail/statistical vectors
      - joins       := edge-level vectors
      - labels      := aggregated runtime targets
    """
    samples = []
    predicates = []
    joins = []
    labels = []

    kept_qids = []

    for qid in qids:
        if qid not in plans_by_query:
            continue
        if qid not in runs_by_query:
            continue

        dag = plans_by_query[qid]
        run_dfs = runs_by_query[qid]

        sample_enc = encode_plan_nodes_as_samples(dag, op2vec)
        predicate_enc = encode_plan_nodes_as_predicates(dag, op2vec)
        join_enc = encode_plan_edges_as_joins(dag, edge2vec, op2vec)

        # Guard against empty sets
        if len(sample_enc) == 0:
            continue
        if len(predicate_enc) == 0:
            continue
        if len(join_enc) == 0:
            # allow zero-edge plans by inserting one all-zero dummy vector
            join_dim = len(next(iter(edge2vec.values()))) + 2 * len(next(iter(op2vec.values()))) + 1
            join_enc = [np.zeros(join_dim, dtype=np.float32)]

        rt = aggregate_query_runtime(run_dfs, xcol=xcol, mode=runtime_mode)

        samples.append(sample_enc)
        predicates.append(predicate_enc)
        joins.append(join_enc)
        labels.append(rt)
        kept_qids.append(qid)

    return samples, predicates, joins, labels, kept_qids


def make_dataset(samples, predicates, joins, labels, max_num_samples, max_num_predicates, max_num_joins):
    """
    Add zero-padding and wrap as TensorDataset.

    Shapes:
      samples    : [batch, max_num_samples, sample_feat_dim]
      predicates : [batch, max_num_predicates, predicate_feat_dim]
      joins      : [batch, max_num_joins, join_feat_dim]
    """
    # ---------- samples ----------
    sample_masks = []
    sample_tensors = []
    for sample in samples:
        sample_tensor = np.vstack(sample).astype(np.float32)
        num_pad = max_num_samples - sample_tensor.shape[0]
        if num_pad < 0:
            raise ValueError("sample_tensor exceeds max_num_samples")

        sample_mask = np.ones((sample_tensor.shape[0], 1), dtype=np.float32)
        sample_tensor = np.pad(sample_tensor, ((0, num_pad), (0, 0)), "constant")
        sample_mask = np.pad(sample_mask, ((0, num_pad), (0, 0)), "constant")

        sample_tensors.append(np.expand_dims(sample_tensor, 0))
        sample_masks.append(np.expand_dims(sample_mask, 0))

    sample_tensors = torch.FloatTensor(np.vstack(sample_tensors))
    sample_masks = torch.FloatTensor(np.vstack(sample_masks))

    # ---------- predicates ----------
    predicate_masks = []
    predicate_tensors = []
    for predicate in predicates:
        predicate_tensor = np.vstack(predicate).astype(np.float32)
        num_pad = max_num_predicates - predicate_tensor.shape[0]
        if num_pad < 0:
            raise ValueError("predicate_tensor exceeds max_num_predicates")

        predicate_mask = np.ones((predicate_tensor.shape[0], 1), dtype=np.float32)
        predicate_tensor = np.pad(predicate_tensor, ((0, num_pad), (0, 0)), "constant")
        predicate_mask = np.pad(predicate_mask, ((0, num_pad), (0, 0)), "constant")

        predicate_tensors.append(np.expand_dims(predicate_tensor, 0))
        predicate_masks.append(np.expand_dims(predicate_mask, 0))

    predicate_tensors = torch.FloatTensor(np.vstack(predicate_tensors))
    predicate_masks = torch.FloatTensor(np.vstack(predicate_masks))

    # ---------- joins ----------
    join_masks = []
    join_tensors = []
    for join in joins:
        join_tensor = np.vstack(join).astype(np.float32)
        num_pad = max_num_joins - join_tensor.shape[0]
        if num_pad < 0:
            raise ValueError("join_tensor exceeds max_num_joins")

        join_mask = np.ones((join_tensor.shape[0], 1), dtype=np.float32)
        join_tensor = np.pad(join_tensor, ((0, num_pad), (0, 0)), "constant")
        join_mask = np.pad(join_mask, ((0, num_pad), (0, 0)), "constant")

        join_tensors.append(np.expand_dims(join_tensor, 0))
        join_masks.append(np.expand_dims(join_mask, 0))

    join_tensors = torch.FloatTensor(np.vstack(join_tensors))
    join_masks = torch.FloatTensor(np.vstack(join_masks))

    # ---------- labels ----------
    target_tensor = torch.FloatTensor(labels).reshape(-1, 1)

    return dataset.TensorDataset(
        sample_tensors,
        predicate_tensors,
        join_tensors,
        target_tensor,
        sample_masks,
        predicate_masks,
        join_masks,
    )


def get_train_test_datasets_from_trino(
    plans_by_query,
    runs_by_query,
    train_qids,
    test_qids,
    *,
    xcol="t_rel_s",
    runtime_mode="mean",
):
    """
    Build MSCN-style train/test TensorDatasets from Trino plans and run traces.

    Returns
    -------
    dicts : list
        [op2vec, edge2vec]
    label_stats : tuple
        (min_val, max_val) used for label normalization
    labels_train_norm : np.ndarray
    labels_test_norm : np.ndarray
    max_num_samples : int
    max_num_predicates : int
    max_num_joins : int
    train_dataset : TensorDataset
    test_dataset : TensorDataset
    kept_train_qids : list[str]
    kept_test_qids : list[str]
    """
    train_plans = [plans_by_query[q] for q in train_qids if q in plans_by_query]

    # Fit vocabularies on training plans only
    operator_names = get_all_operator_names(train_plans)
    edge_types = get_all_edge_types(train_plans)

    op2vec, idx2op = get_set_encoding(operator_names)
    edge2vec, idx2edge = get_set_encoding(edge_types)

    # Encode train/test
    samples_train, predicates_train, joins_train, labels_train, kept_train_qids = encode_queries_from_plans(
        plans_by_query,
        runs_by_query,
        train_qids,
        op2vec,
        edge2vec,
        xcol=xcol,
        runtime_mode=runtime_mode,
    )

    samples_test, predicates_test, joins_test, labels_test, kept_test_qids = encode_queries_from_plans(
        plans_by_query,
        runs_by_query,
        test_qids,
        op2vec,
        edge2vec,
        xcol=xcol,
        runtime_mode=runtime_mode,
    )

    print(f"Number of training samples: {len(labels_train)}")
    print(f"Number of validation samples: {len(labels_test)}")

    if len(labels_train) == 0:
        raise ValueError("No training examples were encoded.")
    if len(labels_test) == 0:
        raise ValueError("No test examples were encoded.")

    # Normalize labels using training stats only
    labels_train_norm, min_val, max_val = normalize_labels(labels_train)
    labels_test_norm, _, _ = normalize_labels(labels_test, min_val=min_val, max_val=max_val)

    # Padding sizes across both splits
    max_num_samples = max(
        max(len(s) for s in samples_train),
        max(len(s) for s in samples_test),
    )
    max_num_predicates = max(
        max(len(p) for p in predicates_train),
        max(len(p) for p in predicates_test),
    )
    max_num_joins = max(
        max(len(j) for j in joins_train),
        max(len(j) for j in joins_test),
    )

    train_dataset = make_dataset(
        samples_train,
        predicates_train,
        joins_train,
        labels_train_norm,
        max_num_samples=max_num_samples,
        max_num_predicates=max_num_predicates,
        max_num_joins=max_num_joins,
    )
    print("Created TensorDataset for training data")

    test_dataset = make_dataset(
        samples_test,
        predicates_test,
        joins_test,
        labels_test_norm,
        max_num_samples=max_num_samples,
        max_num_predicates=max_num_predicates,
        max_num_joins=max_num_joins,
    )
    print("Created TensorDataset for validation data")

    dicts = [op2vec, edge2vec]
    label_stats = (min_val, max_val)

    return (
        dicts,
        label_stats,
        labels_train_norm,
        labels_test_norm,
        max_num_samples,
        max_num_predicates,
        max_num_joins,
        train_dataset,
        test_dataset,
        kept_train_qids,
        kept_test_qids,
    )