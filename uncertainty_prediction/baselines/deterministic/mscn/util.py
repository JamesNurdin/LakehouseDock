import numpy as np


def chunks(l, n):
    for i in range(0, len(l), n):
        yield l[i:i + n]


def idx_to_onehot(idx, num_elements):
    onehot = np.zeros(num_elements, dtype=np.float32)
    onehot[idx] = 1.0
    return onehot


def get_set_encoding(source_set, onehot=True, add_unknown=True):
    source_list = sorted(list(source_set))

    if add_unknown and "UNKNOWN" not in source_list:
        source_list.append("UNKNOWN")

    thing2idx = {s: i for i, s in enumerate(source_list)}
    idx2thing = [s for s in source_list]

    if onehot:
        thing2vec = {s: idx_to_onehot(i, len(source_list)) for i, s in enumerate(source_list)}
        return thing2vec, idx2thing

    return thing2idx, idx2thing


def safe_float(x, default=0.0):
    try:
        return float(x)
    except Exception:
        return default


def safe_len(x):
    if x is None:
        return 0.0
    try:
        return float(len(x))
    except Exception:
        return 0.0


def get_all_operator_names(plans):
    ops = set()
    for dag in plans:
        for node in dag["nodes"].values():
            ops.add(node.get("name", "UNKNOWN"))
    ops.add("UNKNOWN")
    return ops


def get_all_edge_types(plans):
    etypes = set()
    for dag in plans:
        for _, _, etype in dag["edges"]:
            etypes.add(str(etype))
    etypes.add("UNKNOWN")
    return etypes


def estimate_list_to_feature_vector(estimates):
    if not estimates:
        return np.zeros(6, dtype=np.float32)

    row_counts = []
    output_sizes = []
    cpu_costs = []
    mem_costs = []
    net_costs = []

    for est in estimates:
        if not isinstance(est, dict):
            continue
        row_counts.append(np.log1p(max(safe_float(est.get("outputRowCount", 0.0), 0.0), 0.0)))
        output_sizes.append(np.log1p(max(safe_float(est.get("outputSizeInBytes", 0.0), 0.0), 0.0)))
        cpu_costs.append(np.log1p(max(safe_float(est.get("cpuCost", 0.0), 0.0), 0.0)))
        mem_costs.append(np.log1p(max(safe_float(est.get("memoryCost", 0.0), 0.0), 0.0)))
        net_costs.append(np.log1p(max(safe_float(est.get("networkCost", 0.0), 0.0), 0.0)))

    def mean_or_zero(vals):
        vals = [v for v in vals if np.isfinite(v)]
        return float(np.mean(vals)) if vals else 0.0

    return np.array([
        float(len(estimates)),
        mean_or_zero(row_counts),
        mean_or_zero(output_sizes),
        mean_or_zero(cpu_costs),
        mean_or_zero(mem_costs),
        mean_or_zero(net_costs),
    ], dtype=np.float32)


def encode_plan_nodes_as_samples(dag, op2vec):
    out = []
    unk_vec = op2vec.get("UNKNOWN")
    if unk_vec is None:
        raise KeyError("op2vec must contain 'UNKNOWN'")

    for node_id, node in dag["nodes"].items():
        op_name = node.get("name", "UNKNOWN")
        op_vec = op2vec.get(op_name, unk_vec)
        frag_val = np.array([safe_float(node.get("fragment", 0.0), 0.0)], dtype=np.float32)
        outputs_len = np.array([safe_len(node.get("outputs", []))], dtype=np.float32)
        has_est = np.array([1.0 if node.get("estimates") else 0.0], dtype=np.float32)
        vec = np.hstack([op_vec, frag_val, outputs_len, has_est]).astype(np.float32)
        out.append(vec)
    return out


def encode_plan_nodes_as_predicates(dag, op2vec):
    out = []
    unk_vec = op2vec.get("UNKNOWN")
    if unk_vec is None:
        raise KeyError("op2vec must contain 'UNKNOWN'")

    child_counts = {}
    for node_id in dag["nodes"]:
        child_counts[node_id] = 0.0
    for src, dst, etype in dag["edges"]:
        if etype == "child":
            child_counts[src] += 1.0

    for node_id, node in dag["nodes"].items():
        op_name = node.get("name", "UNKNOWN")
        op_vec = op2vec.get(op_name, unk_vec)
        est_vec = estimate_list_to_feature_vector(node.get("estimates", []))
        descriptor_size = np.array([safe_len(node.get("descriptor", {}))], dtype=np.float32)
        child_count = np.array([child_counts[node_id]], dtype=np.float32)
        vec = np.hstack([op_vec, est_vec, descriptor_size, child_count]).astype(np.float32)
        out.append(vec)
    return out


def encode_plan_edges_as_joins(dag, edge2vec, op2vec):
    out = []

    unk_edge_vec = edge2vec.get("UNKNOWN")
    if unk_edge_vec is None:
        raise KeyError("edge2vec must contain 'UNKNOWN'")

    unk_op_vec = op2vec.get("UNKNOWN")
    if unk_op_vec is None:
        raise KeyError("op2vec must contain 'UNKNOWN'")

    nodes = dag["nodes"]
    for src, dst, etype in dag["edges"]:
        edge_vec = edge2vec.get(str(etype), unk_edge_vec)
        src_vec = op2vec.get(nodes[src].get("name", "UNKNOWN"), unk_op_vec)
        dst_vec = op2vec.get(nodes[dst].get("name", "UNKNOWN"), unk_op_vec)

        same_fragment = np.array([
            float(str(nodes[src].get("fragment", "")) == str(nodes[dst].get("fragment", "")))
        ], dtype=np.float32)

        vec = np.hstack([edge_vec, src_vec, dst_vec, same_fragment]).astype(np.float32)
        out.append(vec)
    return out


def normalize_labels(labels, min_val=None, max_val=None):
    labels = np.array([np.log(float(l)) for l in labels], dtype=np.float32)
    if min_val is None:
        min_val = float(labels.min())
    if max_val is None:
        max_val = float(labels.max())
    denom = max(max_val - min_val, 1e-12)
    labels_norm = (labels - min_val) / denom
    labels_norm = np.clip(labels_norm, 0.0, 1.0)
    return labels_norm.astype(np.float32), float(min_val), float(max_val)


def unnormalize_labels(labels_norm, min_val, max_val):
    labels_norm = np.asarray(labels_norm, dtype=np.float32)
    labels_norm = np.clip(labels_norm, 0.0, 1.0)
    labels_log = labels_norm * (max_val - min_val) + min_val
    labels_log = np.clip(labels_log, -50.0, 50.0)
    return np.exp(labels_log).astype(np.float32)