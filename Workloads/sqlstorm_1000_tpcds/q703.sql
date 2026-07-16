WITH item_strings AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_product_name,
        i.i_color,
        i.i_size,
        i.i_manufact,
        LOWER(i.i_item_desc) AS lower_desc,
        REGEXP_REPLACE(i.i_item_desc, '\\s+', '_') AS underscore_desc,
        REPLACE(i.i_product_name, ' ', '') AS compact_name,
        LENGTH(i.i_item_desc) AS desc_len,
        CARDINALITY(SPLIT(i.i_product_name, ' ')) AS word_count,
        CARDINALITY(ARRAY_DISTINCT(SPLIT(i.i_product_name, ' '))) AS unique_word_count,
        REGEXP_EXTRACT(i.i_item_desc, '(.*?)-', 1) AS pre_dash,
        SUBSTRING(i.i_item_id, 1, 3) AS id_prefix,
        COALESCE(i.i_color, 'UNKNOWN') AS color_coalesce,
        CASE WHEN REGEXP_LIKE(i.i_item_desc, '.*[0-9]{2,}.*') THEN true ELSE false END AS has_multi_digit,
        CONCAT(i.i_item_desc, '|', i.i_product_name) AS concat_desc_prod
    FROM item i
),
sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        i.i_item_sk,
        SUM(ss.ss_quantity) AS total_qty,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item_strings i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, i.i_item_sk
    HAVING SUM(ss.ss_quantity) > 50
)
SELECT
    sa.s_store_name,
    sa.d_year,
    i.i_item_id,
    i.i_item_desc,
    i.lower_desc,
    i.underscore_desc,
    i.compact_name,
    i.desc_len,
    i.word_count,
    i.unique_word_count,
    (1.0 * i.unique_word_count / NULLIF(i.word_count, 0)) AS unique_word_ratio,
    i.pre_dash,
    i.id_prefix,
    i.color_coalesce,
    i.has_multi_digit,
    i.concat_desc_prod,
    i.i_product_name,
    REGEXP_REPLACE(i.i_product_name, '[^A-Za-z0-9]', '') AS alphanumeric_name,
    TRIM(i.i_size) AS trimmed_size,
    sa.total_qty,
    sa.total_profit,
    sa.txn_count,
    sa.total_profit / NULLIF(sa.total_qty, 0) AS profit_per_qty,
    SUBSTRING(i.compact_name, 1, 10) AS short_name,
    CONCAT('SKU:', i.i_item_id, '-Store:', sa.s_store_name) AS report_key,
    CONCAT_WS('|', sa.s_store_name, CAST(sa.d_year AS VARCHAR), i.i_item_id) AS partition_key,
    LENGTH(i.compact_name) - LENGTH(REPLACE(i.compact_name, 'A', '')) AS count_A
FROM sales_agg sa
JOIN item_strings i ON sa.i_item_sk = i.i_item_sk
ORDER BY sa.total_profit DESC
LIMIT 50
