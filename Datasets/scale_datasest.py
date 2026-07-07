#!/usr/bin/env python3
"""
Standalone relational CSV scaler.
Derived from DataManagementLab/zero-shot-cost-estimation's
meta_tools/scale_dataset.py, 

Two capabilities, both aimed only at producing CSV output of a target total size:

1. calibrate_scale_csv(...)   -> the scale factor that yields a target *CSV* size,
                                 modelling the digit-growth of offset keys instead of
                                 assuming every copy is the size of the original.
                                 Pure pandas, reads only key columns.

2. scale_to_target_csv(...)   -> the guarantee. Uses the calibrated scale to write the
                                 base copies with Spark (distributed crossJoin), measures
                                 the real bytes on disk, and appends further copy-batches
                                 until the output crosses the target. No estimate is trusted
                                 blindly; the on-disk size is what decides when to stop.
"""

import json
import math
import os

import numpy as np
import pandas as pd
import argparse

from pathlib import Path


# ===========================================================================
# Column order per table.
# Read from the conf.py used by the importer (its TABLES list of StructType
# schemas), so conf.py stays the single source of truth for column order.
# Built at runtime via load_headers_from_conf(); no hardcoded duplicate.
# ===========================================================================
def load_headers_from_conf(conf_path):
    """
    Import a conf.py and return {table_name: [col, col, ...]} taken from each
    entry's StructType schema, preserving field order. conf.py is expected to
    define a TABLES list of dicts with 'name' and 'schema' keys (StructType).
    """
    import importlib.util

    conf_path = str(conf_path)
    spec = importlib.util.spec_from_file_location("_scaler_conf", conf_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Could not load conf module from {conf_path}")
    conf = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(conf)

    if not hasattr(conf, "TABLES"):
        raise AttributeError(f"{conf_path} defines no TABLES list")

    headers = {}
    for entry in conf.TABLES:
        name = entry["name"]
        schema = entry["schema"]
        # StructType supports .fieldNames(); fall back to iterating fields.
        try:
            cols = list(schema.fieldNames())
        except AttributeError:
            cols = [f.name for f in schema.fields]
        headers[name] = cols
    return headers


def merge_table_parts(target_dir, table, sep, write_header, headers):
    """
    Concatenate all Spark part-*.csv files for one table into a single
    <target_dir>/<table>.csv, in part-file order, prepending the header from
    `headers` if write_header is True. Streams bytes so it works on multi-GB
    outputs. Removes the table subdirectory afterwards.
    """
    table_dir = os.path.join(target_dir, table)
    if not os.path.isdir(table_dir):
        raise FileNotFoundError(f"No output directory to merge: {table_dir}")

    parts = sorted(
        os.path.join(table_dir, fn)
        for fn in os.listdir(table_dir)
        if fn.startswith("part-") and fn.endswith(".csv")
    )
    if not parts:
        raise FileNotFoundError(f"No part-*.csv files found in {table_dir}")

    out_path = os.path.join(target_dir, f"{table}.csv")
    with open(out_path, "wb") as out:
        if write_header:
            header = sep.join(headers[table]) + "\n"
            out.write(header.encode("utf-8"))
        for p in parts:
            with open(p, "rb") as src:
                # stream in chunks to avoid loading whole part into memory
                while True:
                    chunk = src.read(16 * 1024 * 1024)
                    if not chunk:
                        break
                    out.write(chunk)

    # only remove the dir once the merged file exists and is non-empty
    if os.path.getsize(out_path) > 0:
        import shutil
        shutil.rmtree(table_dir)
    return out_path


# ===========================================================================
# Schema helpers (no framework deps)
# ===========================================================================
def load_schema(path):
    with open(path) as f:
        schema = json.load(f)
    rels = []
    for child, fk, parent, pcols in schema["relationships"]:
        fk = fk if isinstance(fk, list) else [fk]
        pcols = pcols if isinstance(pcols, list) else [pcols]
        rels.append((child, fk, parent, pcols))
    schema["relationships"] = rels
    return schema


def default_primary_keys(schema):
    return {t: {"id"} for t in schema["tables"]}


def build_scale_columns(schema, primary_keys):
    sc = {t: set(primary_keys.get(t, set())) for t in schema["tables"]}
    for child, fk, parent, pcols in schema["relationships"]:
        sc.setdefault(child, set()).update(fk)
        sc.setdefault(parent, set()).update(pcols)
    return sc


def needed_maxes(schema, primary_keys):
    needed = {t: set(c) for t, c in primary_keys.items() if c}
    for child, fk, parent, pcols in schema["relationships"]:
        needed.setdefault(parent, set()).update(pcols)
    return needed


def numeric_offset(t, c, maxes, relationships):
    """FK -> parent max + 1 ; else own max + 1."""
    offset = None
    for child, fk, parent, pcols in relationships:
        if child != t or c not in fk:
            continue
        offset = maxes[parent][pcols[fk.index(c)]] + 1
    if offset is None:
        offset = maxes[t][c] + 1
    return offset


# ===========================================================================
# 1. CSV size calibration  (pure pandas -- "what scale gives me N GB of CSV?")
# ===========================================================================
def calibrate_scale_csv(data_dir, schema, target_gb, primary_keys=None,
                        sample_rows=200_000, grid_points=48):
    """
    Smallest integer scale S whose total CSV output >= target_gb, accounting for the
    fact that copy k shifts each key by k*offset, so later copies carry more digits and
    are larger than copy 0. Evaluates size(copy k) on a row sample across a grid of k,
    integrates sum_{k=1}^{S-1} size(copy k), and inverts for S.
    """
    primary_keys = primary_keys or default_primary_keys(schema)
    sep = schema["csv_kwargs"]["sep"]
    target_bytes = target_gb * (1024 ** 3)
    scale_columns = build_scale_columns(schema, primary_keys)
    maxes = _maxes_from_csv(data_dir, schema, needed_maxes(schema, primary_keys), sep)

    total_f0 = sum(os.path.getsize(os.path.join(data_dir, f"{t}.csv")) for t in schema["tables"])
    rough_S = max(math.ceil(target_bytes / total_f0), 1)
    k_max = max(4 * rough_S, 64)
    k_grid = np.unique(np.linspace(0, k_max, grid_points).astype(np.int64))

    size_at_k = np.zeros(len(k_grid), dtype=np.float64)
    for t in schema["tables"]:
        path = os.path.join(data_dir, f"{t}.csv")
        f0 = os.path.getsize(path)
        keycols = sorted(scale_columns.get(t, set()))
        if not keycols:
            size_at_k += f0
            continue

        kdf = pd.read_csv(path, sep=sep, usecols=keycols)
        rows_total = len(kdf)
        if rows_total > sample_rows:
            kdf = kdf.sample(sample_rows, random_state=0)
        scale_up = rows_total / len(kdf)

        int_cols = [c for c in keycols if pd.api.types.is_numeric_dtype(kdf[c])]
        str_cols = [c for c in keycols if c not in int_cols]
        offs = {c: numeric_offset(t, c, maxes, schema["relationships"]) for c in int_cols}

        def key_bytes(k):
            b = 0.0
            for c in int_cols:
                vals = kdf[c].to_numpy(dtype="float64") + k * offs[c]
                with np.errstate(invalid="ignore", divide="ignore"):
                    mag = np.abs(vals)
                    digits = np.where(mag < 1, 1, np.floor(np.log10(mag)) + 1)
                lens = np.where(np.isnan(vals), 4.0, digits + (vals < 0))
                b += lens.sum()
            for c in str_cols:
                base = kdf[c].fillna("").astype(str).str.len().to_numpy()
                suffix = 0 if k == 0 else (1 + len(str(k - 1)))
                b += (base + (kdf[c].notna().to_numpy() * suffix)).sum()
            return b * scale_up

        k0_key = key_bytes(0)
        nonkey_per_copy = f0 - k0_key
        for j, k in enumerate(k_grid):
            size_at_k[j] += (f0 if k == 0 else nonkey_per_copy + key_bytes(k))

    cum = np.zeros(len(k_grid))
    cum[0] = size_at_k[0]
    for j in range(1, len(k_grid)):
        cum[j] = cum[j - 1] + 0.5 * (size_at_k[j] + size_at_k[j - 1]) * (k_grid[j] - k_grid[j - 1])

    if cum[-1] < target_bytes:
        slope = (cum[-1] - cum[-2]) / (k_grid[-1] - k_grid[-2])
        S = int(k_grid[-1] + math.ceil((target_bytes - cum[-1]) / slope))
        proj = cum[-1] + slope * (S - k_grid[-1])
    else:
        S = int(math.ceil(np.interp(target_bytes, cum, k_grid)))
        proj = float(np.interp(S, k_grid, cum))

    return {"scale": max(S, 1), "projected_gb": proj / (1024 ** 3), "linear_guess": rough_S}


def _maxes_from_csv(data_dir, schema, needed, sep):
    maxes = {}
    for t, cols in needed.items():
        if not cols:
            continue
        cols = sorted(cols)
        df = pd.read_csv(os.path.join(data_dir, f"{t}.csv"), sep=sep, usecols=cols)
        maxes[t] = {}
        for c in cols:
            m = df[c].max()
            if pd.isna(m):
                raise ValueError(f"{t}.{c} empty/all-null, cannot derive offset")
            maxes[t][c] = int(m)
    return maxes


# ===========================================================================
# 2. Spark generation -> CSV, with measure-and-top-up to guarantee the target
# ===========================================================================
def _spark_maxes(table_dfs, schema, primary_keys):
    from pyspark.sql import functions as F
    maxes = {}
    for t, cols in needed_maxes(schema, primary_keys).items():
        cols = sorted(cols)
        row = table_dfs[t].agg(*[F.max(F.col(c)).alias(c) for c in cols]).collect()[0]
        maxes[t] = {c: int(row[c]) for c in cols}
    return maxes


def scale_table_spark(spark, df, t, scale_columns, maxes, relationships, k_start, k_end):
    """Copies k in [k_start, k_end) of df with offset keys. k_start=0 includes the original."""
    from pyspark.sql import functions as F
    copies = spark.range(k_start, k_end).withColumnRenamed("id", "_k")
    out = df.crossJoin(F.broadcast(copies))
    dtypes = dict(df.dtypes)
    for c in scale_columns.get(t, set()):
        off = numeric_offset(t, c, maxes, relationships)
        if dtypes[c] == "string":
            out = out.withColumn(
                c,
                F.when(F.col("_k") == 0, F.col(c))
                 .otherwise(F.concat(F.col(c), F.lit("_"), (F.col("_k") - 1).cast("string"))),
            )
        else:
            out = out.withColumn(c, (F.col(c).cast("long") + F.col("_k") * F.lit(int(off))).cast("long"))
    return out.drop("_k")


def _dir_size_bytes(dirs):
    """Sum sizes of all files under the given output dirs (local filesystem / PVC mount)."""
    total = 0
    for d in dirs:
        for root, _, files in os.walk(d):
            for fn in files:
                if fn.startswith("part-") or fn.endswith(".csv"):
                    total += os.path.getsize(os.path.join(root, fn))
    return total


def scale_to_target_csv(spark, schema, data_dir, target_dir, target_gb,
                        primary_keys=None, write_header=False, source_header=True,
                        batch=64, out_partitions=None, headers=None):
    """
    Generate CSV until the on-disk total reaches target_gb.

    Starts from the calibrated scale (one Spark write of copies [0, S)), then measures the
    actual bytes on disk and appends further copy-batches until the target is crossed. The
    final batch is sized from the observed bytes-per-copy so it does not overshoot wildly.
    """
    from pyspark.sql import functions as F  # noqa: F401  (kept for parity / future use)

    primary_keys = primary_keys or default_primary_keys(schema)
    scale_columns = build_scale_columns(schema, primary_keys)
    sep = schema["csv_kwargs"]["sep"]
    target_bytes = target_gb * (1024 ** 3)

    # Fail fast: if we're going to write headers, make sure we have one for every
    # table BEFORE spending hours generating data.
    if write_header:
        if not headers:
            raise ValueError("write_header=True but no headers provided "
                             "(pass --conf-path so headers can be read from conf.py).")
        missing = [t for t in schema["tables"] if t not in headers]
        if missing:
            raise KeyError(
                f"--write-header set but conf.py has no schema for: {missing}. "
                f"Check the table names match between the JSON schema and conf.py TABLES."
            )
        for t in schema["tables"]:
            n = len(headers[t])
            print(f"  header[{t}] = {sep.join(headers[t])}  ({n} cols)")

    # upfront scale estimate (CSV-accurate)
    plan = calibrate_scale_csv(data_dir, schema, target_gb, primary_keys)
    S0 = plan["scale"]
    print(f"Calibrated scale: {S0}  (projected {plan['projected_gb']:.1f} GB, "
          f"linear guess was {plan['linear_guess']})")

    # read sources once, cache for repeated batches
    read = spark.read.option("header", str(source_header).lower()).option("sep", sep).option("inferSchema", "true")
    table_dfs = {}
    for t in schema["tables"]:
        df = read.csv(os.path.join(data_dir, f"{t}.csv")).cache()
        df.count()
        table_dfs[t] = df
    maxes = _spark_maxes(table_dfs, schema, primary_keys)

    out_dirs = [os.path.join(target_dir, t) for t in schema["tables"]]

    def write_batch(k0, k1, mode):
        for t in schema["tables"]:
            out = scale_table_spark(spark, table_dfs[t], t, scale_columns, maxes,
                                    schema["relationships"], k0, k1)
            if out_partitions:
                out = out.coalesce(out_partitions)
            # Always write WITHOUT a Spark header: the post-generation merge step
            # prepends a single correct header per table. Letting Spark write headers
            # here would put a header in every part file -> header rows mid-data.
            (out.write.mode(mode)
                .option("header", "false").option("sep", sep)
                .option("nullValue", "NULL")
                .csv(os.path.join(target_dir, t)))

    print(f"Writing base copies 0..{S0-1} ...")
    write_batch(0, S0, "overwrite")
    scale = S0
    size = _dir_size_bytes(out_dirs)
    print(f"  scale={scale}  size={size/1024**3:.2f} / {target_gb} GB")

    while size < target_bytes:
        bytes_per_copy = size / scale
        need = max(1, math.ceil((target_bytes - size) / bytes_per_copy))
        k0, k1 = scale, scale + min(batch, need)
        print(f"Appending copies {k0}..{k1-1} ...")
        write_batch(k0, k1, "append")
        scale = k1
        size = _dir_size_bytes(out_dirs)
        print(f"  scale={scale}  size={size/1024**3:.2f} / {target_gb} GB")

    print(f"Reached {size/1024**3:.2f} GB at scale {scale}.")

    print("Merging part files into single <table>.csv per table ...")
    merged = {}
    for t in schema["tables"]:
        path = merge_table_parts(target_dir, t, sep, write_header, headers)
        mb = os.path.getsize(path) / 1024 ** 2
        print(f"  {t}.csv  ({mb:.1f} MB)")
        merged[t] = path

    return {"scale": scale, "measured_gb": size / (1024 ** 3), "merged": merged}


# ===========================================================================
# Driver
# ===========================================================================
if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="Calibrate or generate scaled CSV data to a target size."
    )

    parser.add_argument(
        "--schema-path",
        required=True,
        help="Path to schema JSON file, e.g. /mnt/user-data/uploads/stats_ceb_sf1.json",
    )

    parser.add_argument(
        "--data-dir",
        required=True,
        help="Directory containing original source CSVs as <table>.csv",
    )

    parser.add_argument(
        "--target-gb",
        type=float,
        default=1024.0,
        help="Target CSV size in GB. Default: 1024.0",
    )

    parser.add_argument(
        "--generate",
        action="store_true",
        help="Run the full Spark-based generation step. If omitted, only calibration is printed.",
    )

    parser.add_argument(
        "--target-dir",
        help="Output directory for generated CSVs. Required when using --generate.",
    )

    parser.add_argument(
        "--batch",
        type=int,
        default=64,
        help="Batch size for Spark generation. Default: 64",
    )

    parser.add_argument(
        "--write-header",
        action="store_true",
        help="Prepend a header row to each merged <table>.csv. Column order is "
             "read from the conf.py given by --conf-path (its TABLES schemas).",
    )

    parser.add_argument(
        "--conf-path",
        default=None,
        help="Path to the importer's conf.py. Required with --write-header: "
             "column names/order for headers are read from its TABLES list.",
    )

    parser.add_argument(
        "--out-partitions",
        type=int,
        default=None,
        help="Coalesce each table's output to this many part files per batch "
             "before the merge step. Lower = fewer/larger parts (less merge I/O), "
             "but too low starves parallelism. Default: leave Spark's partitioning.",
    )

    parser.add_argument(
        "--source-header",
        action="store_true",
        default=True,
        help="Treat source CSVs as having headers. Default: True",
    )

    parser.add_argument(
        "--no-source-header",
        dest="source_header",
        action="store_false",
        help="Treat source CSVs as not having headers.",
    )

    parser.add_argument(
        "--csv-sep",
        default=None,
        help="Override the CSV separator from the schema, e.g. ',' or '|'.",
    )

    args = parser.parse_args()

    schema_path = Path(args.schema_path)
    data_dir = Path(args.data_dir)

    if not schema_path.exists():
        raise FileNotFoundError(f"Schema path does not exist: {schema_path}")

    if not data_dir.exists():
        raise FileNotFoundError(f"Data directory does not exist: {data_dir}")

    schema = load_schema(str(schema_path))

    if args.csv_sep is not None:
        schema.setdefault("csv_kwargs", {})
        schema["csv_kwargs"]["sep"] = args.csv_sep
        print(f"Using CSV separator override: {repr(args.csv_sep)}")

    # --- just the scale factor for the target CSV size; no Spark needed ---
    scale = calibrate_scale_csv(str(data_dir), schema, args.target_gb)
    print(scale)

    # --- full generate-until-target-size CSV; requires Spark ---
    if args.generate:
        if not args.target_dir:
            raise ValueError("--target-dir is required when using --generate")

        # Load headers from conf.py up front so a bad path/missing table fails
        # before Spark spins up, not hours into generation.
        headers = None
        if args.write_header:
            if not args.conf_path:
                raise ValueError("--write-header requires --conf-path "
                                 "(headers are read from conf.py).")
            conf_path = Path(args.conf_path)
            if not conf_path.exists():
                raise FileNotFoundError(f"conf.py not found: {conf_path}")
            headers = load_headers_from_conf(conf_path)
            print(f"Loaded headers for {len(headers)} tables from {conf_path}")

        target_dir = Path(args.target_dir)
        target_dir.mkdir(parents=True, exist_ok=True)

        from pyspark.sql import SparkSession

        spark = (
            SparkSession.builder
            .appName("scale_to_target_csv")
            .getOrCreate()
        )

        res = scale_to_target_csv(
            spark,
            schema,
            str(data_dir),
            str(target_dir),
            args.target_gb,
            write_header=args.write_header,
            source_header=args.source_header,
            batch=args.batch,
            out_partitions=args.out_partitions,
            headers=headers,
        )

        print(res)

# python ./scale_datasest.py --schema-path /mnt/primary/Main/Datasets/schemas/stats_ceb_sf1.json --data-dir /mnt/primary/Main/Datasets/Stats-CEB/datasets --target-gb 1024 --csv-sep ","

#pip install pyspark==3.5.1
# python ./scale_datasest.py --schema-path /mnt/primary/Main/Datasets/schemas/stats_ceb_sf1.json --data-dir /mnt/primary/Main/Datasets/Stats-CEB/datasets --target-dir /mnt/raid3-extra/datasets/stats_ceb --target-gb 1024 --csv-sep "," --generate --batch 64 --write-header --conf-path /mnt/primary/Main/Datasets/Stats-CEB/conf.py