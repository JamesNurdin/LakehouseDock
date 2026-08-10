"""
Dataset config for the imdb (Join Order Benchmark) schema, for use with
generate_iceberg_tables.py.

This dataset predates the trino_stack framework: it was originally loaded by
an ad-hoc, now-lost process directly into /mnt/iceberg-imdb-1tb, and every
column of every table in that result came back NULL (confirmed at the Parquet
level: null_count == num_values for all columns, all tables, including tiny
unscaled ones like kind_type -- so the corruption is a write-time parsing
bug in that old loader, not something fixable by re-registering the schema).
This conf.py re-ports the dataset through the current, working CSV -> Iceberg
pipeline instead of trying to repair the old one.

Source data: /mnt/iceberg-imdb-1tb/raw/scaled_imdb_1TB_csv.tar.zst
  -- one file per table at the archive root: <table>.csv

Format confirmed two ways:
  1. Directly reading the first few KB of title.csv out of the archive:
     comma-delimited, header row present, fields quoted with '"' only when
     they contain the delimiter (e.g. a title containing a comma), empty
     string for NULL.
  2. The canonical JOB schema.json shipped with the vendored
     zero-shot-cost-estimation project (old/related_work/.../datasets/imdb/
     schema.json), whose db_load_kwargs for postgres is exactly:
       DELIMITER ',' QUOTE '"' ESCAPE '\' NULL '' CSV HEADER;
     i.e. comma delimiter, header=true, quote='"', escape='\', null=''.
     Spark's CSV reader defaults for quote/escape already match this, so
     generate_iceberg_tables.py (which only exposes delimiter/nullValue/
     header/mode from the conf, not quote/escape) needs no code changes.

Column names/order per table come from the canonical JOB postgres DDL in
that same vendored schema_sql/postgres.sql, and were cross-checked against
`DESCRIBE` on the (data-corrupt but schema-intact) live iceberg.imdb.* tables
-- both agree.

Types: every surrogate id / foreign key column is typed as LongType rather
than IntegerType. The source CSVs are themselves already the "scaled to 1TB"
output of an earlier scaling pass (this file predates scale_datasest.py, but
presumably used the same kind of per-copy numeric-key-offset trick), and a
sibling dataset (ssb) hit exactly this failure mode: offset-scaled surrogate
keys silently overflowing a 32-bit INTEGER column and being written as NULL.
Since we haven't fully decompressed these CSVs to confirm every table's max
id fits in 32 bits, LongType is the safe default for every id/FK column.
Genuinely small, never-scaled numeric fields (production_year, season_nr,
episode_nr, nr_order) stay IntegerType.
"""

from pyspark.sql.types import (
    StructType, StructField,
    LongType, IntegerType, StringType,
)

DATASET_SLUG = "imdb"

# Raw CSVs live directly under the extraction root, e.g.
# /mnt/raid3-extra/imdb_raw/<table>.csv -- pass that as --raw-base-path.
RAW_SUBDIR = ""

# Iceberg warehouse output; pass --warehouse-path /mnt/iceberg-imdb-1tb/warehouse
# explicitly at import time (kept here only as a documented fallback).
ICEBERG_SUBDIR = "warehouse"


def csv_table(name, schema, *, large=False):
    return {
        "name": name,
        "relative_dir": "",
        "file_name": f"{name}.csv",
        "format": "csv",
        "header": True,
        "mode": "FAILFAST",
        "delimiter": ",",
        "nullValue": "",
        "schema": schema,
        "large": large,
    }


TABLES = [

    csv_table("name", StructType([
        StructField("id", LongType(), True),
        StructField("name", StringType(), True),
        StructField("imdb_index", StringType(), True),
        StructField("imdb_id", LongType(), True),
        StructField("gender", StringType(), True),
        StructField("name_pcode_cf", StringType(), True),
        StructField("name_pcode_nf", StringType(), True),
        StructField("surname_pcode", StringType(), True),
        StructField("md5sum", StringType(), True),
    ]), large=True),

    csv_table("aka_name", StructType([
        StructField("id", LongType(), True),
        StructField("person_id", LongType(), True),
        StructField("name", StringType(), True),
        StructField("imdb_index", StringType(), True),
        StructField("name_pcode_cf", StringType(), True),
        StructField("name_pcode_nf", StringType(), True),
        StructField("surname_pcode", StringType(), True),
        StructField("md5sum", StringType(), True),
    ]), large=True),

    csv_table("title", StructType([
        StructField("id", LongType(), True),
        StructField("title", StringType(), True),
        StructField("imdb_index", StringType(), True),
        StructField("kind_id", LongType(), True),
        StructField("production_year", IntegerType(), True),
        StructField("imdb_id", LongType(), True),
        StructField("phonetic_code", StringType(), True),
        StructField("episode_of_id", LongType(), True),
        StructField("season_nr", IntegerType(), True),
        StructField("episode_nr", IntegerType(), True),
        StructField("series_years", StringType(), True),
        StructField("md5sum", StringType(), True),
    ]), large=True),

    csv_table("cast_info", StructType([
        StructField("id", LongType(), True),
        StructField("person_id", LongType(), True),
        StructField("movie_id", LongType(), True),
        StructField("person_role_id", LongType(), True),
        StructField("note", StringType(), True),
        StructField("nr_order", IntegerType(), True),
        StructField("role_id", LongType(), True),
    ]), large=True),

    csv_table("char_name", StructType([
        StructField("id", LongType(), True),
        StructField("name", StringType(), True),
        StructField("imdb_index", StringType(), True),
        StructField("imdb_id", LongType(), True),
        StructField("name_pcode_nf", StringType(), True),
        StructField("surname_pcode", StringType(), True),
        StructField("md5sum", StringType(), True),
    ]), large=True),

    csv_table("company_name", StructType([
        StructField("id", LongType(), True),
        StructField("name", StringType(), True),
        StructField("country_code", StringType(), True),
        StructField("imdb_id", LongType(), True),
        StructField("name_pcode_nf", StringType(), True),
        StructField("name_pcode_sf", StringType(), True),
        StructField("md5sum", StringType(), True),
    ])),

    csv_table("company_type", StructType([
        StructField("id", LongType(), True),
        StructField("kind", StringType(), True),
    ])),

    csv_table("info_type", StructType([
        StructField("id", LongType(), True),
        StructField("info", StringType(), True),
    ])),

    csv_table("keyword", StructType([
        StructField("id", LongType(), True),
        StructField("keyword", StringType(), True),
        StructField("phonetic_code", StringType(), True),
    ]), large=True),

    csv_table("kind_type", StructType([
        StructField("id", LongType(), True),
        StructField("kind", StringType(), True),
    ])),

    csv_table("movie_companies", StructType([
        StructField("id", LongType(), True),
        StructField("movie_id", LongType(), True),
        StructField("company_id", LongType(), True),
        StructField("company_type_id", LongType(), True),
        StructField("note", StringType(), True),
    ]), large=True),

    csv_table("movie_info", StructType([
        StructField("id", LongType(), True),
        StructField("movie_id", LongType(), True),
        StructField("info_type_id", LongType(), True),
        StructField("info", StringType(), True),
        StructField("note", StringType(), True),
    ]), large=True),

    csv_table("movie_info_idx", StructType([
        StructField("id", LongType(), True),
        StructField("movie_id", LongType(), True),
        StructField("info_type_id", LongType(), True),
        StructField("info", StringType(), True),
        StructField("note", StringType(), True),
    ]), large=True),

    csv_table("movie_keyword", StructType([
        StructField("id", LongType(), True),
        StructField("movie_id", LongType(), True),
        StructField("keyword_id", LongType(), True),
    ]), large=True),

    csv_table("person_info", StructType([
        StructField("id", LongType(), True),
        StructField("person_id", LongType(), True),
        StructField("info_type_id", LongType(), True),
        StructField("info", StringType(), True),
        StructField("note", StringType(), True),
    ]), large=True),

]
