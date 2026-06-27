#!/usr/bin/env python3
"""
Generic Spark-to-Iceberg dataset importer.

The dataset-specific table definitions live in:

    /mnt/primary/Main/Datasets/<DatasetName>/conf.py

Example for BigBenchV2:

    /mnt/primary/Main/Datasets/
    ├── import_dataset.py
    └── BigBenchV2/
        ├── conf.py
        ├── data/sf1/hive_text/...
        └── schema/Iceberg/sf1/

Typical usage:

    cd /mnt/primary/Main/Datasets

    spark-submit \
      --packages org.apache.iceberg:iceberg-spark-runtime-3.2_2.12:0.14.1 \
      import_dataset.py \
      --dataset-name BigBenchV2 \
      --scale-factor 1 \
      --catalog-name iceberg \
      --catalog-type hive \
      --metastore-uri thrift://<hive-metastore-service>.pgr24james.svc.cluster.local:9083 \
      --overwrite

The importer:
  1. Loads <DatasetName>/conf.py.
  2. Checks the expected raw files exist.
  3. Reads each table using Spark.
  4. Creates an Iceberg namespace/schema.
  5. Writes each table to Iceberg.
  6. Optionally validates the tables.
"""

from __future__ import annotations

import argparse
import importlib.util
import sys
from pathlib import Path
from typing import Any, Optional

from pyspark.sql import SparkSession, DataFrame
from pyspark.sql import functions as F


def path_uri(path: Path) -> str:
    return str(path.resolve())

def quote_ident(name: str) -> str:
    return "`" + str(name).replace("`", "``") + "`"


def namespace_identifier(catalog: str, namespace: str) -> str:
    return f"{quote_ident(catalog)}.{quote_ident(namespace)}"


def table_identifier(catalog: str, namespace: str, table: str) -> str:
    return f"{quote_ident(catalog)}.{quote_ident(namespace)}.{quote_ident(table)}"


def load_dataset_conf(conf_path: Path):
    if not conf_path.is_file():
        raise FileNotFoundError(f"Dataset config not found: {conf_path}")

    spec = importlib.util.spec_from_file_location("dataset_conf", conf_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Could not load config module from: {conf_path}")

    module = importlib.util.module_from_spec(spec)
    sys.modules["dataset_conf"] = module
    spec.loader.exec_module(module)

    if not hasattr(module, "TABLES"):
        raise AttributeError(f"{conf_path} must define TABLES")

    return module


def build_spark(args: argparse.Namespace, warehouse_path: Path) -> SparkSession:
    builder = (
        SparkSession.builder
        .appName(f"Dataset Iceberg Import: {args.dataset_name} SF{args.scale_factor}")
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
        .config(f"spark.sql.catalog.{args.catalog_name}", "org.apache.iceberg.spark.SparkCatalog")
        .config(f"spark.sql.catalog.{args.catalog_name}.warehouse", path_uri(warehouse_path))
    )

    if args.catalog_type == "hive":
        if not args.metastore_uri:
            raise ValueError("--metastore-uri is required when --catalog-type hive")
        builder = (
            builder
            .config(f"spark.sql.catalog.{args.catalog_name}.type", "hive")
            .config(f"spark.sql.catalog.{args.catalog_name}.uri", args.metastore_uri)
        )
    elif args.catalog_type == "hadoop":
        builder = builder.config(f"spark.sql.catalog.{args.catalog_name}.type", "hadoop")
    else:
        raise ValueError(f"Unsupported catalog type: {args.catalog_type}")

    for item in args.extra_conf or []:
        if "=" not in item:
            raise ValueError(f"Invalid --extra-conf value: {item}. Expected key=value")
        key, value = item.split("=", 1)
        builder = builder.config(key, value)

    return builder.getOrCreate()


def default_dataset_slug(conf_module: Any, dataset_name: str) -> str:
    return getattr(conf_module, "DATASET_SLUG", dataset_name.lower())


def get_raw_base_path(args: argparse.Namespace, dataset_root: Path, conf_module: Any) -> Path:
    if args.raw_base_path:
        return Path(args.raw_base_path).resolve()

    raw_subdir = args.raw_subdir or getattr(conf_module, "RAW_SUBDIR", "hive_text")
    return dataset_root / "data" / f"sf{args.scale_factor}" / raw_subdir


def get_warehouse_path(args: argparse.Namespace, dataset_root: Path, conf_module: Any) -> Path:
    if args.warehouse_path:
        return Path(args.warehouse_path).resolve()

    iceberg_subdir = args.iceberg_subdir or getattr(conf_module, "ICEBERG_SUBDIR", "Iceberg")
    return dataset_root / "schema" / iceberg_subdir / f"sf{args.scale_factor}"


def table_path(raw_base_path: Path, table: dict[str, Any]) -> Path:
    return raw_base_path / table["relative_dir"] / table["file_name"]


def validate_files(raw_base_path: Path, tables: list[dict[str, Any]]) -> None:
    print(f"Checking staged files under: {raw_base_path}")
    missing: list[Path] = []

    for table in tables:
        p = table_path(raw_base_path, table)
        if not p.is_file():
            missing.append(p)
        else:
            print(f"  OK {table['name']:<20} {p} ({p.stat().st_size / (1024 ** 2):.2f} MiB)")

    if missing:
        print("\nMissing required files:")
        for p in missing:
            print(f"  {p}")
        raise FileNotFoundError("The staged dataset files are incomplete.")


def read_table(spark: SparkSession, raw_base_path: Path, table: dict[str, Any]) -> DataFrame:
    fmt = table.get("format", "csv").lower()
    p = str(table_path(raw_base_path, table).resolve())

    if fmt == "text":
        column_name = table.get("text_column", "line")
        return spark.read.text(p).select(F.col("value").alias(column_name))

    if fmt == "csv":
        reader = (
            spark.read
            .option("header", str(table.get("header", False)).lower())
            .option("mode", table.get("mode", "FAILFAST"))
        )

        if "delimiter" in table:
            reader = reader.option("delimiter", table["delimiter"])

        if table.get("schema") is not None:
            reader = reader.schema(table["schema"])

        return reader.csv(p)

    if fmt == "json":
        reader = spark.read.option("mode", table.get("mode", "FAILFAST"))
        if table.get("schema") is not None:
            reader = reader.schema(table["schema"])
        return reader.json(p)

    if fmt in {"keyed_json", "pipe_json"}:
        # BigBenchV2's `-j` output is not always pure JSON-lines.
        # Several files are encoded as:
        #
        #   <numeric_id>|{"field": "value", ...}
        #
        # This reader keeps the numeric id as `id_column`, parses the JSON
        # payload using the provided payload schema, and optionally renames
        # fields from the payload to preserve the table schema used elsewhere.
        schema = table.get("schema")
        if schema is None:
            raise ValueError(f"{fmt} table {table.get('name')} requires a payload schema")

        id_column = table.get("id_column")
        if not id_column:
            raise ValueError(f"{fmt} table {table.get('name')} requires id_column")

        field_renames = table.get("field_renames", {})
        json_options = {"mode": table.get("mode", "FAILFAST")}

        raw = spark.read.text(p).select(F.col("value").alias("_line"))
        parsed = raw.select(
            F.regexp_extract(F.col("_line"), r"^([^|]*)\|(.*)$", 1).cast("long").alias(id_column),
            F.from_json(
                F.regexp_extract(F.col("_line"), r"^[^|]*\|(.*)$", 1),
                schema,
                json_options,
            ).alias("_json"),
        )

        cols = [F.col(id_column)]
        for field in schema.fields:
            src_name = field.name
            dst_name = field_renames.get(src_name, src_name)
            cols.append(F.col(f"_json.`{src_name}`").alias(dst_name))

        return parsed.select(*cols)

    if fmt == "parquet":
        return spark.read.parquet(p)

    raise ValueError(f"Unsupported table format for {table.get('name')}: {fmt}")


def apply_table_options(df: DataFrame, table: dict[str, Any], *, coalesce: Optional[int]) -> DataFrame:
    table_coalesce = table.get("coalesce", coalesce)
    if table_coalesce and int(table_coalesce) > 0:
        return df.coalesce(int(table_coalesce))
    return df


def create_namespace(
    spark: SparkSession,
    *,
    catalog: str,
    namespace: str,
    location: Optional[Path],
    no_namespace_location: bool,
) -> None:
    ns = namespace_identifier(catalog, namespace)

    if location is not None and not no_namespace_location:
        try:
            spark.sql(f"CREATE NAMESPACE IF NOT EXISTS {ns} LOCATION '{path_uri(location)}'")
            return
        except Exception as exc:
            print(f"Could not create namespace with explicit LOCATION; falling back. Reason: {exc}")

    spark.sql(f"CREATE NAMESPACE IF NOT EXISTS {ns}")


def write_iceberg_table(
    df: DataFrame,
    *,
    catalog: str,
    namespace: str,
    table_name: str,
    warehouse_path: Path,
    overwrite: bool,
) -> None:
    ident = table_identifier(catalog, namespace, table_name)

    table_location = str(warehouse_path / f"{namespace}.db" / table_name)

    if overwrite:
        df.sql_ctx.sparkSession.sql(f"DROP TABLE IF EXISTS {ident}")

    (
        df.writeTo(ident)
        .using("iceberg")
        .tableProperty("location", table_location)
        .create()
    )


def validate_iceberg_tables(
    spark: SparkSession,
    *,
    catalog: str,
    namespace: str,
    tables: list[dict[str, Any]],
    count_large_tables: bool,
    preview_rows: int,
) -> None:
    print("\nValidating Iceberg tables")

    for table in tables:
        name = table["name"]
        ident = table_identifier(catalog, namespace, name)
        validate_mode = table.get("validate", "count")
        is_large = bool(table.get("large", False))

        if validate_mode == "preview" or (is_large and not count_large_tables):
            print(f"\nPreviewing {ident}")
            spark.sql(f"SELECT * FROM {ident} LIMIT {preview_rows}").show(truncate=120)
        else:
            print(f"\nCounting {ident}")
            spark.sql(f"SELECT count(*) AS rows FROM {ident}").show()


def import_dataset(args: argparse.Namespace) -> None:
    datasets_root = Path(args.datasets_root).resolve()
    dataset_root = datasets_root / args.dataset_name
    conf_path = Path(args.conf_path).resolve() if args.conf_path else dataset_root / "conf.py"

    conf_module = load_dataset_conf(conf_path)

    tables = list(getattr(conf_module, "TABLES"))
    if args.only_table:
        allowed = set(args.only_table)
        tables = [t for t in tables if t["name"] in allowed]

    if not tables:
        raise ValueError("No tables selected for import.")

    raw_base_path = get_raw_base_path(args, dataset_root, conf_module)
    warehouse_path = get_warehouse_path(args, dataset_root, conf_module)
    warehouse_path.mkdir(parents=True, exist_ok=True)

    dataset_slug = default_dataset_slug(conf_module, args.dataset_name)
    namespace = args.namespace or f"{dataset_slug}_sf{args.scale_factor}"

    validate_files(raw_base_path, tables)

    spark = build_spark(args, warehouse_path)

    try:
        print("\nSpark version:", spark.version)
        print("Dataset:", args.dataset_name)
        print("Config:", conf_path)
        print("Catalog:", args.catalog_name)
        print("Catalog type:", args.catalog_type)
        print("Namespace:", namespace)
        print("Warehouse path:", warehouse_path)

        create_namespace(
            spark,
            catalog=args.catalog_name,
            namespace=namespace,
            location=warehouse_path,
            no_namespace_location=args.no_namespace_location,
        )

        for table in tables:
            name = table["name"]
            print(f"\nImporting {name}")
            df = read_table(spark, raw_base_path, table)

            if args.preview:
                df.show(args.preview_rows, truncate=120)

            df = apply_table_options(df, table, coalesce=args.coalesce)

            write_iceberg_table(
                df,
                catalog=args.catalog_name,
                namespace=namespace,
                table_name=name,
                warehouse_path=warehouse_path,
                overwrite=args.overwrite,
            )

        if args.validate:
            validate_iceberg_tables(
                spark,
                catalog=args.catalog_name,
                namespace=namespace,
                tables=tables,
                count_large_tables=args.count_large_tables,
                preview_rows=args.preview_rows,
            )

        print("\nDone.")
        print(f"Created Iceberg schema: {args.catalog_name}.{namespace}")
        print("Example Trino queries:")
        for table in tables[:10]:
            print(f"  SELECT * FROM {args.catalog_name}.{namespace}.{table['name']} LIMIT 5;")

    finally:
        spark.stop()


def parse_args(argv: Optional[list[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generic Spark-to-Iceberg dataset importer.")

    parser.add_argument("--datasets-root", default="/mnt/primary/Main/Datasets")
    parser.add_argument("--dataset-name", required=True)
    parser.add_argument("--scale-factor", default="1")

    parser.add_argument("--conf-path", default=None)
    parser.add_argument("--raw-base-path", default=None)
    parser.add_argument("--raw-subdir", default=None)
    parser.add_argument("--warehouse-path", default=None)
    parser.add_argument("--iceberg-subdir", default=None)

    parser.add_argument("--catalog-name", default="iceberg")
    parser.add_argument("--catalog-type", choices=["hive", "hadoop"], default="hive")
    parser.add_argument("--metastore-uri", default=None)
    parser.add_argument("--namespace", default=None)

    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--only-table", action="append", default=[], help="Import only this table. Can be repeated.")

    parser.add_argument("--validate", action="store_true", default=True)
    parser.add_argument("--no-validate", dest="validate", action="store_false")
    parser.add_argument("--count-large-tables", action="store_true")
    parser.add_argument("--preview", action="store_true")
    parser.add_argument("--preview-rows", type=int, default=5)

    parser.add_argument("--coalesce", type=int, default=None)
    parser.add_argument("--no-namespace-location", action="store_true")
    parser.add_argument("--extra-conf", action="append", default=[], help="Extra Spark conf, format key=value. Can be repeated.")

    return parser.parse_args(argv)


if __name__ == "__main__":
    import_dataset(parse_args())

# called for 1TB ldbc snb
# ./spark-3.2.1-bin-hadoop3.2/bin/spark-submit --master local[8] --driver-memory 90G --conf spark.driver.maxResultSize=4G --conf spark.sql.files.maxPartitionBytes=64m --conf spark.sql.shuffle.partitions=64 --conf spark.default.parallelism=64 --packages org.apache.iceberg:iceberg-spark-runtime-3.2_2.12:0.14.1 generate_iceberg_tables.py --dataset-name ldbc_cnb --scale-factor 1000 --conf-path /mnt/raid3/datasets/sf1000/conf.py --raw-base-path /mnt/raid3/datasets/sf1000 --warehouse-path /mnt/iceberg/warehouse/ --catalog-name iceberg --catalog-type hive --metastore-uri thrift://hive-metastore-lakehouse-a.pgr24james.svc.cluster.local:9083 --namespace ldbc_cnb_sf1000 --overwrite --no-validate

#./spark-3.2.1-bin-hadoop3.2/bin/spark-submit --master local[8] --driver-memory 90G --conf spark.driver.maxResultSize=4G --conf spark.sql.files.maxPartitionBytes=512m --conf spark.sql.shuffle.partitions=64 --conf spark.default.parallelism=64 --packages org.apache.iceberg:iceberg-spark-runtime-3.2_2.12:0.14.1 generate_iceberg_tables.py --dataset-name BigBenchV2 --scale-factor 1000 --conf-path /mnt/raid3-extra/datasets/BigBenchV2/sf1000/conf.py --raw-base-path /mnt/raid3-extra/datasets/BigBenchV2/sf1000 --warehouse-path /mnt/iceberg/warehouse/ --catalog-name iceberg --catalog-type hive --metastore-uri thrift://hive-metastore-lakehouse-a.pgr24james.svc.cluster.local:9083 --namespace bigbenchv2_sf1000 --overwrite --no-validate --only-table web_logs