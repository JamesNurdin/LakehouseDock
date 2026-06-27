#!/usr/bin/env bash
set -euo pipefail

# Spark installation used to run the import job.
export SPARK_HOME="/mnt/primary/Main/Datasets/spark-3.2.1-bin-hadoop3.2"
export PATH="$SPARK_HOME/bin:$PATH"

# Root directory containing datasets and the generic import script.
export DATASETS_ROOT="/mnt/primary/Main/Datasets"

# Iceberg Spark runtime JAR used by spark-submit.
export ICEBERG_JAR="$SPARK_HOME/jars/iceberg-spark-runtime-3.2_2.12-0.14.1.jar"

# Hive Metastore URI for the target lakehouse instance.
export METASTORE_URI="thrift://hive-metastore-lakehouse-d.pgr24james.svc.cluster.local:9083"

# Physical Iceberg warehouse root used by the metastore.
export WAREHOUSE_PATH="/mnt/iceberg/warehouse"

# Dataset folder name under DATASETS_ROOT.
export DATASET_NAME="ldbc_snb"

# Generated dataset scale factor.
export SCALE_FACTOR="0.003"

# Target Iceberg namespace/schema.
export NAMESPACE="ldbc_snb_bi_sf0003"

# LDBC files and config are directly in:
# /mnt/primary/Main/Datasets/ldbc_snb
export RAW_BASE_PATH="$DATASETS_ROOT/$DATASET_NAME"
export CONF_PATH="$DATASETS_ROOT/$DATASET_NAME/conf.py"

cd "$DATASETS_ROOT"

spark-submit \
  --driver-memory 8g \
  --executor-memory 8g \
  --conf spark.driver.maxResultSize=2g \
  --conf spark.sql.shuffle.partitions=32 \
  --conf spark.sql.files.maxPartitionBytes=67108864 \
  --jars "$ICEBERG_JAR" \
  "$DATASETS_ROOT/import_dataset.py" \
  --dataset-name "$DATASET_NAME" \
  --scale-factor "$SCALE_FACTOR" \
  --conf-path "$CONF_PATH" \
  --raw-base-path "$RAW_BASE_PATH" \
  --catalog-name iceberg \
  --catalog-type hive \
  --metastore-uri "$METASTORE_URI" \
  --warehouse-path "$WAREHOUSE_PATH" \
  --namespace "$NAMESPACE" \
  --no-namespace-location \
  --overwrite