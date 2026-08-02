WITH sales_filtered AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        s.s_store_name,
        i.i_category,
        i.i_brand,
        i.i_units,
        i.i_item_desc,
        regexp_extract(i.i_item_desc, '(\\d+)', 1) AS desc_number,
        s.s_store_name || ' - ' || i.i_brand AS store_brand_concat,
        SUBSTR(i.i_product_name, 1, 10) AS product_name_prefix
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND regexp_like(i.i_units, '^Carton')
      AND s.s_store_name LIKE 'A%'
),
returned_items AS (
    SELECT DISTINCT sr.sr_item_sk
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
),
non_returned_item_keys AS (
    SELECT ss_item_sk
    FROM (SELECT DISTINCT ss_item_sk FROM sales_filtered) si
    EXCEPT
    SELECT sr_item_sk FROM returned_items
),
sales_non_returned AS (
    SELECT sf.*
    FROM sales_filtered sf
    JOIN non_returned_item_keys nri
        ON sf.ss_item_sk = nri.ss_item_sk
)
SELECT
    s_store_name,
    i_category,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss_item_sk) AS distinct_items,
    MIN(desc_number) AS sample_desc_number,
    MIN(store_brand_concat) AS sample_store_brand
FROM sales_non_returned
GROUP BY ROLLUP (s_store_name, i_category)
ORDER BY s_store_name, i_category
LIMIT 100
