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
    def __init__(self, batches: List[Dict[str, Any]]):
        self.batches = batches

    def __len__(self):
        return len(self.batches)

    def __getitem__(self, idx):
        return self.batches[idx]


def tlstm_collate_fn_identity(batch):
    if len(batch) != 1:
        raise ValueError("TLSTMBatchDataset should usually be used with batch_size=1.")
    return batch[0]


class _TreeNode:
    def __init__(self, node_id: str, payload: Dict[str, Any]):
        self.node_id = node_id
        self.payload = payload
        self.children: List["_TreeNode"] = []
        self.level_id: int = -1
        self.idx: int = -1


def _binarize_tree(
    dag: Dict[str, Any],
    root_id: str,
    children_map: Dict[str, List[str]],
) -> _TreeNode:
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
    nodes_by_level: List[List[_TreeNode]] = []

    def dfs(node: _TreeNode, level: int):
        node.level_id = level
        if len(nodes_by_level) <= level:
            nodes_by_level.append([])
        nodes_by_level[level].append(node)
        node.idx = len(nodes_by_level[level])
        for child in node.children:
            dfs(child, level + 1)

    dfs(root, 0)
    return nodes_by_level


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


# ---------------------------------------------------------------------
# TPool-ready condition tree encoding
# ---------------------------------------------------------------------

COND_KIND_PAD = 0
COND_KIND_LEAF = 1
COND_KIND_AND = 2
COND_KIND_OR = 3


def _leaf_token_from_estimate_tokens(
    node_payload: Dict[str, Any],
    condition_op_dim: int,
) -> List[np.ndarray]:
    estimates = node_payload.get("estimates", [])
    est_vec = estimate_list_to_feature_vector(estimates)

    tokens: List[np.ndarray] = []
    for i, val in enumerate(est_vec):
        tok = np.zeros(condition_op_dim, dtype=np.float32)
        tok[0] = float(i + 1)
        tok[1] = float(val)
        tokens.append(tok)
    return tokens


def _leaf_token_from_descriptor_tokens(
    node_payload: Dict[str, Any],
    condition_op_dim: int,
) -> List[np.ndarray]:
    descriptor = node_payload.get("descriptor", {})
    outputs = node_payload.get("outputs", [])

    desc_count = float(len(descriptor))
    out_count = float(len(outputs))

    tokens: List[np.ndarray] = []

    tok1 = np.zeros(condition_op_dim, dtype=np.float32)
    tok1[0] = 1.0
    tok1[1] = desc_count
    tokens.append(tok1)

    tok2 = np.zeros(condition_op_dim, dtype=np.float32)
    tok2[0] = 2.0
    tok2[1] = out_count
    tokens.append(tok2)

    return tokens


def _build_flat_condition_tree(
    leaf_tokens: List[np.ndarray],
    condition_op_dim: int,
    max_condition_nodes: int,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    """
    Fallback tree:
      root = AND
      children = leaf tokens

    Returns
    -------
    feats  : [T, D]
    mapping: [T, 2]
    kinds  : [T]
    """
    if len(leaf_tokens) == 0:
        leaf_tokens = [np.zeros(condition_op_dim, dtype=np.float32)]

    feats: List[np.ndarray] = []
    mapping: List[List[int]] = []
    kinds: List[int] = []

    # root first
    root_feat = np.zeros(condition_op_dim, dtype=np.float32)
    feats.append(root_feat)
    kinds.append(COND_KIND_AND)

    # add leaves
    for tok in leaf_tokens:
        feats.append(tok.astype(np.float32))
        kinds.append(COND_KIND_LEAF)

    # build binary fold from leaves if needed
    if len(leaf_tokens) == 1:
        mapping.append([1, 0])
    elif len(leaf_tokens) == 2:
        mapping.append([1, 2])
    else:
        # root points to a synthetic internal AND chain and final leaf
        next_internal_idx = len(feats)
        mapping.append([next_internal_idx, len(leaf_tokens)])

        current_left = 1
        current_right = 2
        for i in range(2, len(leaf_tokens)):
            feats.append(np.zeros(condition_op_dim, dtype=np.float32))
            kinds.append(COND_KIND_AND)
            if i == 2:
                mapping.append([current_left, current_right])
            else:
                mapping.append([len(mapping), i])

        # the above is a lightweight fallback; structure only needs to be consistent enough
        # for min/max pooling, not semantically exact

    while len(mapping) < len(feats):
        mapping.append([0, 0])

    feats = feats[:max_condition_nodes]
    mapping = mapping[:max_condition_nodes]
    kinds = kinds[:max_condition_nodes]

    if len(feats) < max_condition_nodes:
        pad_n = max_condition_nodes - len(feats)
        feats = feats + [np.zeros(condition_op_dim, dtype=np.float32) for _ in range(pad_n)]
        mapping = mapping + [[0, 0] for _ in range(pad_n)]
        kinds = kinds + [COND_KIND_PAD for _ in range(pad_n)]

    return (
        np.asarray(feats, dtype=np.float32),
        np.asarray(mapping, dtype=np.int64),
        np.asarray(kinds, dtype=np.int64),
    )


def _build_condition_tree_from_payload(
    node_payload: Dict[str, Any],
    branch: str,
    condition_op_dim: int,
    max_condition_nodes: int,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    """
    Try explicit tree first, else fallback to flat synthetic tree.

    Expected explicit format (if available later):
    {
      "kind": "and" | "or" | "leaf",
      "feat": [...],            # only for leaf
      "children": [ ... ]
    }
    """
    explicit = (
        node_payload.get(f"{branch}_tree")
        or node_payload.get(branch)
    )

    if explicit is None:
        if branch == "condition1":
            leaf_tokens = _leaf_token_from_estimate_tokens(node_payload, condition_op_dim)
        else:
            leaf_tokens = _leaf_token_from_descriptor_tokens(node_payload, condition_op_dim)

        return _build_flat_condition_tree(
            leaf_tokens=leaf_tokens,
            condition_op_dim=condition_op_dim,
            max_condition_nodes=max_condition_nodes,
        )

    feats: List[np.ndarray] = []
    mapping: List[List[int]] = []
    kinds: List[int] = []

    def rec(tree_obj) -> int:
        kind = str(tree_obj.get("kind", "leaf")).lower()
        children = tree_obj.get("children", [])

        if kind == "leaf":
            feat = np.asarray(tree_obj.get("feat", np.zeros(condition_op_dim)), dtype=np.float32)
            if feat.shape[0] < condition_op_dim:
                feat = np.pad(feat, (0, condition_op_dim - feat.shape[0]), "constant")
            feat = feat[:condition_op_dim]
            feats.append(feat)
            mapping.append([0, 0])
            kinds.append(COND_KIND_LEAF)
            return len(feats)

        feat = np.zeros(condition_op_dim, dtype=np.float32)
        feats.append(feat)
        mapping.append([0, 0])
        kinds.append(COND_KIND_AND if kind == "and" else COND_KIND_OR)
        my_idx = len(feats)

        child_ids = [rec(ch) for ch in children[:2]]
        while len(child_ids) < 2:
            child_ids.append(0)
        mapping[my_idx - 1] = child_ids[:2]
        return my_idx

    rec(explicit)

    feats = feats[:max_condition_nodes]
    mapping = mapping[:max_condition_nodes]
    kinds = kinds[:max_condition_nodes]

    if len(feats) < max_condition_nodes:
        pad_n = max_condition_nodes - len(feats)
        feats = feats + [np.zeros(condition_op_dim, dtype=np.float32) for _ in range(pad_n)]
        mapping = mapping + [[0, 0] for _ in range(pad_n)]
        kinds = kinds + [COND_KIND_PAD for _ in range(pad_n)]

    return (
        np.asarray(feats, dtype=np.float32),
        np.asarray(mapping, dtype=np.int64),
        np.asarray(kinds, dtype=np.int64),
    )


def _make_sample_vector(
    node_payload: Dict[str, Any],
    sample_dim: int,
) -> Tuple[np.ndarray, float]:
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
    condition_op_dim: int,
    max_condition_nodes: int,
    extra_dim: int,
    sample_dim: int,
):
    operator_vec = _make_operator_vector(node_payload, op2vec)
    extra_info_vec = _make_extra_info_vector(
        node_payload,
        num_children=num_children,
        remote_in_count=remote_in_count,
        remote_out_count=remote_out_count,
        extra_dim=extra_dim,
    )

    condition1_feats, condition1_mapping, condition1_kinds = _build_condition_tree_from_payload(
        node_payload,
        branch="condition1",
        condition_op_dim=condition_op_dim,
        max_condition_nodes=max_condition_nodes,
    )
    condition2_feats, condition2_mapping, condition2_kinds = _build_condition_tree_from_payload(
        node_payload,
        branch="condition2",
        condition_op_dim=condition_op_dim,
        max_condition_nodes=max_condition_nodes,
    )

    sample_vec, condition_mask = _make_sample_vector(
        node_payload,
        sample_dim=sample_dim,
    )

    return (
        operator_vec,
        extra_info_vec,
        condition1_feats,
        condition1_mapping,
        condition1_kinds,
        condition2_feats,
        condition2_mapping,
        condition2_kinds,
        sample_vec,
        condition_mask,
    )


def encode_plan_trino(
    dag: Dict[str, Any],
    op2vec: Dict[str, np.ndarray],
    *,
    condition_op_dim: int,
    max_condition_nodes: int,
    extra_dim: int,
    sample_dim: int,
):
    operators, extra_infos = [], []
    condition1_feats, condition1_mapping, condition1_kinds = [], [], []
    condition2_feats, condition2_mapping, condition2_kinds = [], [], []
    samples, condition_masks, mapping = [], [], []

    root_id, children_map = build_child_tree(dag)
    remote_in, remote_out = count_remote_edges(dag)

    root = _binarize_tree(dag, root_id, children_map)
    nodes_by_level = _assign_levels(root)

    original_child_counts = {nid: len(children_map.get(nid, [])) for nid in dag["nodes"].keys()}

    for level in nodes_by_level:
        operators.append([])
        extra_infos.append([])
        condition1_feats.append([])
        condition1_mapping.append([])
        condition1_kinds.append([])
        condition2_feats.append([])
        condition2_mapping.append([])
        condition2_kinds.append([])
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

            (
                operator,
                extra_info,
                c1f,
                c1m,
                c1k,
                c2f,
                c2m,
                c2k,
                sample,
                condition_mask,
            ) = encode_node_trino(
                payload,
                op2vec,
                num_children=num_children,
                remote_in_count=r_in,
                remote_out_count=r_out,
                condition_op_dim=condition_op_dim,
                max_condition_nodes=max_condition_nodes,
                extra_dim=extra_dim,
                sample_dim=sample_dim,
            )

            operators[-1].append(operator)
            extra_infos[-1].append(extra_info)
            condition1_feats[-1].append(c1f)
            condition1_mapping[-1].append(c1m)
            condition1_kinds[-1].append(c1k)
            condition2_feats[-1].append(c2f)
            condition2_mapping[-1].append(c2m)
            condition2_kinds[-1].append(c2k)
            samples[-1].append(sample)
            condition_masks[-1].append(condition_mask)

            if len(node.children) == 2:
                mapping[-1].append([node.children[0].idx, node.children[1].idx])
            elif len(node.children) == 1:
                mapping[-1].append([node.children[0].idx, 0])
            else:
                mapping[-1].append([0, 0])

    return (
        operators,
        extra_infos,
        condition1_feats,
        condition1_mapping,
        condition1_kinds,
        condition2_feats,
        condition2_mapping,
        condition2_kinds,
        samples,
        condition_masks,
        mapping,
    )


def _merge_plans_level(level1, level2, is_mapping: bool = False):
    for idx, level in enumerate(level2):
        if idx >= len(level1):
            level1.append([])

        if is_mapping:
            if idx < len(level1) - 1:
                base = len(level1[idx + 1])
                for i in range(len(level)):
                    if isinstance(level[i], list):
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
    condition_op_dim: int,
    max_condition_nodes: int,
    extra_dim: int,
    sample_dim: int,
    label_min: float,
    label_max: float,
) -> Dict[str, Any]:
    target_runtime_batch = []
    operators_batch = []
    extra_infos_batch = []
    condition1_feats_batch = []
    condition1_mapping_batch = []
    condition1_kinds_batch = []
    condition2_feats_batch = []
    condition2_mapping_batch = []
    condition2_kinds_batch = []
    samples_batch = []
    condition_masks_batch = []
    mapping_batch = []
    kept_qids = []

    for qid in qids:
        if qid not in plans_by_query or qid not in runs_by_query:
            continue

        dag = plans_by_query[qid]
        runtime = aggregate_query_runtime(runs_by_query[qid], xcol=xcol, mode=runtime_mode)

        (
            operators,
            extra_infos,
            c1f,
            c1m,
            c1k,
            c2f,
            c2m,
            c2k,
            samples,
            condition_masks,
            mapping,
        ) = encode_plan_trino(
            dag,
            op2vec,
            condition_op_dim=condition_op_dim,
            max_condition_nodes=max_condition_nodes,
            extra_dim=extra_dim,
            sample_dim=sample_dim,
        )

        target_runtime_batch.append(runtime)
        operators_batch = _merge_plans_level(operators_batch, operators)
        extra_infos_batch = _merge_plans_level(extra_infos_batch, extra_infos)
        condition1_feats_batch = _merge_plans_level(condition1_feats_batch, c1f)
        condition1_mapping_batch = _merge_plans_level(condition1_mapping_batch, c1m)
        condition1_kinds_batch = _merge_plans_level(condition1_kinds_batch, c1k)
        condition2_feats_batch = _merge_plans_level(condition2_feats_batch, c2f)
        condition2_mapping_batch = _merge_plans_level(condition2_mapping_batch, c2m)
        condition2_kinds_batch = _merge_plans_level(condition2_kinds_batch, c2k)
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

    condition1_feats_batch = np.array([
        np.pad(np.asarray(v, dtype=np.float32), ((0, max_nodes - len(v)), (0, 0), (0, 0)), "constant")
        for v in condition1_feats_batch
    ], dtype=np.float32)

    condition1_mapping_batch = np.array([
        np.pad(np.asarray(v, dtype=np.int64), ((0, max_nodes - len(v)), (0, 0), (0, 0)), "constant")
        for v in condition1_mapping_batch
    ], dtype=np.int64)

    condition1_kinds_batch = np.array([
        np.pad(np.asarray(v, dtype=np.int64), ((0, max_nodes - len(v)), (0, 0)), "constant")
        for v in condition1_kinds_batch
    ], dtype=np.int64)

    condition2_feats_batch = np.array([
        np.pad(np.asarray(v, dtype=np.float32), ((0, max_nodes - len(v)), (0, 0), (0, 0)), "constant")
        for v in condition2_feats_batch
    ], dtype=np.float32)

    condition2_mapping_batch = np.array([
        np.pad(np.asarray(v, dtype=np.int64), ((0, max_nodes - len(v)), (0, 0), (0, 0)), "constant")
        for v in condition2_mapping_batch
    ], dtype=np.int64)

    condition2_kinds_batch = np.array([
        np.pad(np.asarray(v, dtype=np.int64), ((0, max_nodes - len(v)), (0, 0)), "constant")
        for v in condition2_kinds_batch
    ], dtype=np.int64)

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
        "condition1_feats": torch.FloatTensor(condition1_feats_batch),
        "condition1_mapping": torch.LongTensor(condition1_mapping_batch),
        "condition1_kinds": torch.LongTensor(condition1_kinds_batch),
        "condition2_feats": torch.FloatTensor(condition2_feats_batch),
        "condition2_mapping": torch.LongTensor(condition2_mapping_batch),
        "condition2_kinds": torch.LongTensor(condition2_kinds_batch),
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
    condition_op_dim=16,
    max_condition_nodes=8,
    extra_dim=16,
    sample_dim=32,
):
    train_plans = [plans_by_query[q] for q in train_qids if q in plans_by_query]
    operator_names = set(get_all_operator_names(train_plans))
    operator_names.add("UNKNOWN")
    operator_names.add("FOLD_NODE")

    op2vec, idx2op = get_set_encoding(operator_names)

    train_labels = [
        aggregate_query_runtime(runs_by_query[q], xcol=xcol, mode=runtime_mode)
        for q in train_qids
        if q in runs_by_query
    ]
    _, min_val, max_val = normalize_labels(train_labels)

    train_batches = []
    for qid_chunk in _chunk_list(train_qids, batch_size):
        train_batches.append(
            make_data_trino(
                qids=qid_chunk,
                plans_by_query=plans_by_query,
                runs_by_query=runs_by_query,
                op2vec=op2vec,
                xcol=xcol,
                runtime_mode=runtime_mode,
                condition_op_dim=condition_op_dim,
                max_condition_nodes=max_condition_nodes,
                extra_dim=extra_dim,
                sample_dim=sample_dim,
                label_min=min_val,
                label_max=max_val,
            )
        )

    test_batches = []
    for qid_chunk in _chunk_list(test_qids, batch_size):
        test_batches.append(
            make_data_trino(
                qids=qid_chunk,
                plans_by_query=plans_by_query,
                runs_by_query=runs_by_query,
                op2vec=op2vec,
                xcol=xcol,
                runtime_mode=runtime_mode,
                condition_op_dim=condition_op_dim,
                max_condition_nodes=max_condition_nodes,
                extra_dim=extra_dim,
                sample_dim=sample_dim,
                label_min=min_val,
                label_max=max_val,
            )
        )

    train_dataset = TLSTMBatchDataset(train_batches)
    test_dataset = TLSTMBatchDataset(test_batches)

    return {
        "op2vec": op2vec,
        "idx2op": idx2op,
        "label_stats": (min_val, max_val),
        "condition_op_dim": condition_op_dim,
        "max_condition_nodes": max_condition_nodes,
        "extra_dim": extra_dim,
        "sample_dim": sample_dim,
        "operator_dim": len(next(iter(op2vec.values()))),
        "train_dataset": train_dataset,
        "test_dataset": test_dataset,
    }