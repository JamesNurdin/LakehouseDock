from __future__ import annotations

from typing import Dict, Any, List, Tuple
import numpy as np
import torch
from torch.utils.data import Dataset

from uncertainty_prediction.baselines.deterministic.tlstm.util import (
    get_all_operator_names,
    get_set_encoding,
    build_child_tree,
    count_remote_edges,
    aggregate_query_runtime,
    normalize_labels,
    estimate_list_to_feature_vector,
    safe_float,
)


class TLSTMBatchDataset(Dataset):
    """
    Dataset of already-batched level tensors, similar in spirit to the
    original notebook's saved batch files.
    """
    def __init__(self, batches: List[Dict[str, Any]]):
        self.batches = batches

    def __len__(self):
        return len(self.batches)

    def __getitem__(self, idx):
        return self.batches[idx]


def tlstm_collate_fn_identity(batch):
    """
    DataLoader collate_fn for pre-batched examples.
    Use batch_size=1 in the DataLoader and unwrap the single dict.
    """
    if len(batch) != 1:
        raise ValueError("TLSTMBatchDataset should usually be used with batch_size=1.")
    return batch[0]


# ---------------------------------------------------------------------
# Tree helpers
# ---------------------------------------------------------------------

class _TreeNode:
    def __init__(self, node_id: str, payload: Dict[str, Any]):
        self.node_id = node_id
        self.payload = payload
        self.children: List["_TreeNode"] = []
        self.level_id: int = -1
        self.idx: int = -1  # 1-based index within level, matching notebook logic


def _binarize_tree(
    dag: Dict[str, Any],
    root_id: str,
    children_map: Dict[str, List[str]],
) -> _TreeNode:
    """
    Build a binary tree from child edges.

    If a node has >2 children, we left-fold them with synthetic nodes so the
    downstream mapping logic stays binary, like the notebook expects.
    """
    zero_payload_template = {
        "name": "FOLD_NODE",
        "fragment": "0",
        "descriptor": {},
        "outputs": [],
        "estimates": [],
    }

    synth_counter = {"n": 0}

    def build(node_id: str) -> _TreeNode:
        payload = dag["nodes"][node_id]
        kids = children_map[node_id]

        node = _TreeNode(node_id=node_id, payload=payload)

        if len(kids) == 0:
            return node
        if len(kids) == 1:
            node.children = [build(kids[0])]
            return node
        if len(kids) == 2:
            node.children = [build(kids[0]), build(kids[1])]
            return node

        # >2 children: fold into binary chain
        left = build(kids[0])
        right = build(kids[1])

        acc = _TreeNode(
            node_id=f"__fold_{synth_counter['n']}",
            payload=zero_payload_template.copy(),
        )
        synth_counter["n"] += 1
        acc.children = [left, right]

        for k in kids[2:]:
            nxt = _TreeNode(
                node_id=f"__fold_{synth_counter['n']}",
                payload=zero_payload_template.copy(),
            )
            synth_counter["n"] += 1
            nxt.children = [acc, build(k)]
            acc = nxt

        node.children = [acc]
        return node

    return build(root_id)


def _assign_levels(root: _TreeNode) -> List[List[_TreeNode]]:
    """
    DFS assign levels and 1-based indices within each level,
    matching the exported notebook's convention.
    """
    nodes_by_level: List[List[_TreeNode]] = []

    def dfs(node: _TreeNode, level: int):
        node.level_id = level
        if len(nodes_by_level) <= level:
            nodes_by_level.append([])
        nodes_by_level[level].append(node)
        node.idx = len(nodes_by_level[level])  # 1-based
        for child in node.children:
            dfs(child, level + 1)

    dfs(root, 0)
    return nodes_by_level


# ---------------------------------------------------------------------
# Feature encoding
# ---------------------------------------------------------------------

def _make_operator_vector(
    node_payload: Dict[str, Any],
    op2vec: Dict[str, np.ndarray],
) -> np.ndarray:
    name = node_payload.get("name", "UNKNOWN")
    if name not in op2vec:
        name = "UNKNOWN"
    return op2vec[name].astype(np.float32)


def _make_extra_info_vector(
    node_payload: Dict[str, Any],
    num_children: int,
    remote_in_count: float,
    remote_out_count: float,
    extra_dim: int,
) -> np.ndarray:
    """
    Trino replacement for the notebook's extra_infos block.

    We keep this compact and pad/truncate to extra_dim.
    """
    fragment = safe_float(node_payload.get("fragment", 0.0), 0.0)
    outputs_len = float(len(node_payload.get("outputs", [])))
    descriptor_len = float(len(node_payload.get("descriptor", {})))
    has_estimates = 1.0 if node_payload.get("estimates") else 0.0

    base = np.array([
        fragment,
        outputs_len,
        descriptor_len,
        float(num_children),
        float(remote_in_count),
        float(remote_out_count),
        has_estimates,
    ], dtype=np.float32)

    if len(base) < extra_dim:
        base = np.pad(base, (0, extra_dim - len(base)), "constant")
    else:
        base = base[:extra_dim]

    return base.astype(np.float32)


def _make_condition_sequences(
    node_payload: Dict[str, Any],
    condition_max_num: int,
    condition_op_dim: int,
) -> Tuple[np.ndarray, np.ndarray]:
    """
    Build two condition tensors per node, analogous to condition1/condition2
    in the exported notebook.

    For Trino:
    - condition1 = estimate-derived tokens
    - condition2 = descriptor/output-derived tokens
    """
    estimates = node_payload.get("estimates", [])
    est_vec = estimate_list_to_feature_vector(estimates)  # length 6

    # condition1: estimate tokens
    condition1_tokens: List[np.ndarray] = []
    for i, val in enumerate(est_vec):
        tok = np.zeros(condition_op_dim, dtype=np.float32)
        tok[0] = float(i + 1)  # weak token type marker
        tok[1] = float(val)
        condition1_tokens.append(tok)

    # condition2: descriptor/output tokens
    descriptor = node_payload.get("descriptor", {})
    outputs = node_payload.get("outputs", [])

    desc_count = float(len(descriptor))
    out_count = float(len(outputs))

    condition2_tokens: List[np.ndarray] = []
    tok1 = np.zeros(condition_op_dim, dtype=np.float32)
    tok1[0] = 1.0
    tok1[1] = desc_count
    condition2_tokens.append(tok1)

    tok2 = np.zeros(condition_op_dim, dtype=np.float32)
    tok2[0] = 2.0
    tok2[1] = out_count
    condition2_tokens.append(tok2)

    def pad_tokens(tokens: List[np.ndarray]) -> np.ndarray:
        tokens = tokens[:condition_max_num]
        if len(tokens) == 0:
            tokens = [np.zeros(condition_op_dim, dtype=np.float32)]
        arr = np.stack(tokens, axis=0)
        if arr.shape[0] < condition_max_num:
            arr = np.pad(arr, ((0, condition_max_num - arr.shape[0]), (0, 0)), "constant")
        return arr.astype(np.float32)

    return pad_tokens(condition1_tokens), pad_tokens(condition2_tokens)


def _make_sample_vector(
    node_payload: Dict[str, Any],
    sample_dim: int,
) -> Tuple[np.ndarray, float]:
    """
    Trino replacement for the notebook's 1000-bit sample bitmap branch.

    We use a fixed-width compact summary vector and a mask bit.
    """
    est_vec = estimate_list_to_feature_vector(node_payload.get("estimates", []))
    descriptor_len = float(len(node_payload.get("descriptor", {})))
    outputs_len = float(len(node_payload.get("outputs", [])))
    fragment = safe_float(node_payload.get("fragment", 0.0), 0.0)

    vec = np.concatenate([
        est_vec,
        np.array([descriptor_len, outputs_len, fragment], dtype=np.float32),
    ]).astype(np.float32)

    if len(vec) < sample_dim:
        vec = np.pad(vec, (0, sample_dim - len(vec)), "constant")
    else:
        vec = vec[:sample_dim]

    has_condition = 1.0 if node_payload.get("estimates") or node_payload.get("descriptor") else 0.0
    return vec.astype(np.float32), has_condition


def encode_node_trino(
    node_payload: Dict[str, Any],
    op2vec: Dict[str, np.ndarray],
    *,
    num_children: int,
    remote_in_count: float,
    remote_out_count: float,
    condition_max_num: int,
    condition_op_dim: int,
    extra_dim: int,
    sample_dim: int,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray, float]:
    operator_vec = _make_operator_vector(node_payload, op2vec)
    extra_info_vec = _make_extra_info_vector(
        node_payload,
        num_children=num_children,
        remote_in_count=remote_in_count,
        remote_out_count=remote_out_count,
        extra_dim=extra_dim,
    )
    condition1_vec, condition2_vec = _make_condition_sequences(
        node_payload,
        condition_max_num=condition_max_num,
        condition_op_dim=condition_op_dim,
    )
    sample_vec, condition_mask = _make_sample_vector(
        node_payload,
        sample_dim=sample_dim,
    )
    return operator_vec, extra_info_vec, condition1_vec, condition2_vec, sample_vec, condition_mask


# ---------------------------------------------------------------------
# Single-plan encoding to level tensors
# ---------------------------------------------------------------------

def encode_plan_trino(
    dag: Dict[str, Any],
    op2vec: Dict[str, np.ndarray],
    *,
    condition_max_num: int,
    condition_op_dim: int,
    extra_dim: int,
    sample_dim: int,
) -> Tuple[List, List, List, List, List, List, List]:
    """
    Closest Trino analogue of encode_plan_job(...) in the exported notebook.
    """
    operators, extra_infos, condition1s, condition2s, samples, condition_masks, mapping = (
        [], [], [], [], [], [], []
    )

    root_id, children_map = build_child_tree(dag)
    remote_in, remote_out = count_remote_edges(dag)

    root = _binarize_tree(dag, root_id, children_map)
    nodes_by_level = _assign_levels(root)

    # helpful lookup for original child counts
    original_child_counts = {nid: len(children_map.get(nid, [])) for nid in dag["nodes"].keys()}

    for level in nodes_by_level:
        operators.append([])
        extra_infos.append([])
        condition1s.append([])
        condition2s.append([])
        samples.append([])
        condition_masks.append([])
        mapping.append([])

        for node in level:
            payload = node.payload
            node_id = node.node_id

            if node_id.startswith("__fold_"):
                num_children = len(node.children)
                r_in = 0.0
                r_out = 0.0
            else:
                num_children = original_child_counts.get(node_id, 0)
                r_in = remote_in.get(node_id, 0.0)
                r_out = remote_out.get(node_id, 0.0)

            operator, extra_info, condition1, condition2, sample, condition_mask = encode_node_trino(
                payload,
                op2vec,
                num_children=num_children,
                remote_in_count=r_in,
                remote_out_count=r_out,
                condition_max_num=condition_max_num,
                condition_op_dim=condition_op_dim,
                extra_dim=extra_dim,
                sample_dim=sample_dim,
            )

            operators[-1].append(operator)
            extra_infos[-1].append(extra_info)
            condition1s[-1].append(condition1)
            condition2s[-1].append(condition2)
            samples[-1].append(sample)
            condition_masks[-1].append(condition_mask)

            if len(node.children) == 2:
                mapping[-1].append([node.children[0].idx, node.children[1].idx])
            elif len(node.children) == 1:
                mapping[-1].append([node.children[0].idx, 0])
            else:
                mapping[-1].append([0, 0])

    return operators, extra_infos, condition1s, condition2s, samples, condition_masks, mapping


# ---------------------------------------------------------------------
# Batch merging, very close to merge_plans_level/make_data_job
# ---------------------------------------------------------------------

def _merge_plans_level(level1, level2, is_mapping: bool = False):
    for idx, level in enumerate(level2):
        if idx >= len(level1):
            level1.append([])

        if is_mapping:
            if idx < len(level1) - 1:
                base = len(level1[idx + 1])
                for i in range(len(level)):
                    if level[i][0] > 0:
                        level[i][0] += base
                    if level[i][1] > 0:
                        level[i][1] += base

        level1[idx] += level
    return level1


def make_data_trino(
    qids: List[str],
    plans_by_query: Dict[str, Any],
    runs_by_query: Dict[str, Any],
    op2vec: Dict[str, np.ndarray],
    *,
    xcol: str,
    runtime_mode: str,
    condition_max_num: int,
    condition_op_dim: int,
    extra_dim: int,
    sample_dim: int,
    label_min: float,
    label_max: float,
) -> Dict[str, Any]:
    target_runtime_batch = []
    operators_batch = []
    extra_infos_batch = []
    condition1s_batch = []
    condition2s_batch = []
    samples_batch = []
    condition_masks_batch = []
    mapping_batch = []
    kept_qids = []

    for qid in qids:
        if qid not in plans_by_query or qid not in runs_by_query:
            continue

        dag = plans_by_query[qid]
        runtime = aggregate_query_runtime(runs_by_query[qid], xcol=xcol, mode=runtime_mode)

        operators, extra_infos, condition1s, condition2s, samples, condition_masks, mapping = encode_plan_trino(
            dag,
            op2vec,
            condition_max_num=condition_max_num,
            condition_op_dim=condition_op_dim,
            extra_dim=extra_dim,
            sample_dim=sample_dim,
        )

        target_runtime_batch.append(runtime)
        operators_batch = _merge_plans_level(operators_batch, operators)
        extra_infos_batch = _merge_plans_level(extra_infos_batch, extra_infos)
        condition1s_batch = _merge_plans_level(condition1s_batch, condition1s)
        condition2s_batch = _merge_plans_level(condition2s_batch, condition2s)
        samples_batch = _merge_plans_level(samples_batch, samples)
        condition_masks_batch = _merge_plans_level(condition_masks_batch, condition_masks)
        mapping_batch = _merge_plans_level(mapping_batch, mapping, is_mapping=True)
        kept_qids.append(qid)

    if len(target_runtime_batch) == 0:
        raise ValueError("No valid queries found for batch construction.")

    max_nodes = max(len(o) for o in operators_batch)

    operators_batch = np.array([
        np.pad(np.asarray(v, dtype=np.float32), ((0, max_nodes - len(v)), (0, 0)), "constant")
        for v in operators_batch
    ], dtype=np.float32)

    extra_infos_batch = np.array([
        np.pad(np.asarray(v, dtype=np.float32), ((0, max_nodes - len(v)), (0, 0)), "constant")
        for v in extra_infos_batch
    ], dtype=np.float32)

    condition1s_batch = np.array([
        np.pad(np.asarray(v, dtype=np.float32), ((0, max_nodes - len(v)), (0, 0), (0, 0)), "constant")
        for v in condition1s_batch
    ], dtype=np.float32)

    condition2s_batch = np.array([
        np.pad(np.asarray(v, dtype=np.float32), ((0, max_nodes - len(v)), (0, 0), (0, 0)), "constant")
        for v in condition2s_batch
    ], dtype=np.float32)

    samples_batch = np.array([
        np.pad(np.asarray(v, dtype=np.float32), ((0, max_nodes - len(v)), (0, 0)), "constant")
        for v in samples_batch
    ], dtype=np.float32)

    condition_masks_batch = np.array([
        np.pad(np.asarray(v, dtype=np.float32), (0, max_nodes - len(v)), "constant")
        for v in condition_masks_batch
    ], dtype=np.float32)

    mapping_batch = np.array([
        np.pad(np.asarray(v, dtype=np.int64), ((0, max_nodes - len(v)), (0, 0)), "constant")
        for v in mapping_batch
    ], dtype=np.int64)

    labels_norm, _, _ = normalize_labels(target_runtime_batch, min_val=label_min, max_val=label_max)

    return {
        "target_runtime": torch.FloatTensor(labels_norm),
        "operators": torch.FloatTensor(operators_batch),
        "extra_infos": torch.FloatTensor(extra_infos_batch),
        "condition1s": torch.FloatTensor(condition1s_batch),
        "condition2s": torch.FloatTensor(condition2s_batch),
        "samples": torch.FloatTensor(samples_batch),
        "condition_masks": torch.FloatTensor(condition_masks_batch),
        "mapping": torch.LongTensor(mapping_batch),
        "qids": kept_qids,
    }


def _chunk_list(arr: List[str], batch_size: int) -> List[List[str]]:
    return [arr[i:i + batch_size] for i in range(0, len(arr), batch_size)]


def get_train_test_datasets_from_trino(
    plans_by_query,
    runs_by_query,
    train_qids,
    test_qids,
    *,
    xcol="t_rel_s",
    runtime_mode="mean",
    batch_size=64,
    condition_max_num=8,
    condition_op_dim=16,
    extra_dim=16,
    sample_dim=32,
):
    """
    Returns pre-batched TLSTM datasets that are structurally close to the
    exported notebook pipeline.
    """
    train_plans = [plans_by_query[q] for q in train_qids if q in plans_by_query]
    operator_names = set(get_all_operator_names(train_plans))
    operator_names.add("UNKNOWN")
    operator_names.add("FOLD_NODE")

    op2vec, idx2op = get_set_encoding(operator_names)

    # label normalization fit on training runtimes only
    train_labels = [
        aggregate_query_runtime(runs_by_query[q], xcol=xcol, mode=runtime_mode)
        for q in train_qids
        if q in runs_by_query
    ]
    labels_train_norm, min_val, max_val = normalize_labels(train_labels)

    train_batches = []
    for qid_chunk in _chunk_list(train_qids, batch_size):
        batch = make_data_trino(
            qids=qid_chunk,
            plans_by_query=plans_by_query,
            runs_by_query=runs_by_query,
            op2vec=op2vec,
            xcol=xcol,
            runtime_mode=runtime_mode,
            condition_max_num=condition_max_num,
            condition_op_dim=condition_op_dim,
            extra_dim=extra_dim,
            sample_dim=sample_dim,
            label_min=min_val,
            label_max=max_val,
        )
        train_batches.append(batch)

    test_batches = []
    for qid_chunk in _chunk_list(test_qids, batch_size):
        batch = make_data_trino(
            qids=qid_chunk,
            plans_by_query=plans_by_query,
            runs_by_query=runs_by_query,
            op2vec=op2vec,
            xcol=xcol,
            runtime_mode=runtime_mode,
            condition_max_num=condition_max_num,
            condition_op_dim=condition_op_dim,
            extra_dim=extra_dim,
            sample_dim=sample_dim,
            label_min=min_val,
            label_max=max_val,
        )
        test_batches.append(batch)

    train_dataset = TLSTMBatchDataset(train_batches)
    test_dataset = TLSTMBatchDataset(test_batches)

    return {
        "op2vec": op2vec,
        "idx2op": idx2op,
        "label_stats": (min_val, max_val),
        "condition_max_num": condition_max_num,
        "condition_op_dim": condition_op_dim,
        "extra_dim": extra_dim,
        "sample_dim": sample_dim,
        "operator_dim": len(next(iter(op2vec.values()))),
        "train_dataset": train_dataset,
        "test_dataset": test_dataset,
    }