WITH base_sales AS (
    SELECT
        s.s_store_name AS s_store_name,
        i.i_brand AS i_brand,
        i.i_item_id AS i_item_id,
        i.i_product_name AS i_product_name,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        t.t_hour,
        t.t_minute,
        regexp_extract(i.i_product_name, '^(\\w+)', 1) AS first_word,
        CASE
            WHEN regexp_like(i.i_product_name, '(?i)Premium') THEN 'Premium'
            ELSE 'Other'
        END AS product_type
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE i.i_product_name LIKE '%Deluxe%'
      AND regexp_like(i.i_product_name, '(?i)Premium|Deluxe')
),

grouped_sales AS (
    SELECT
        s_store_name,
        i_brand,
        product_type,
        first_word,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT i_item_id) AS distinct_items_sold
    FROM base_sales
    GROUP BY s_store_name, i_brand, product_type, first_word
    HAVING SUM(ss_ext_sales_price) > 1000
)

SELECT
    s_store_name,
    i_brand,
    product_type,
    first_word,
    SUBSTR(first_word, 1, 2) AS first_word_abbr,
    CONCAT(s_store_name, ' - ', CAST(i_brand AS VARCHAR)) AS store_brand,
    total_sales,
    distinct_items_sold,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_sales DESC) AS rank_within_store,
    SUM(total_sales) OVER (PARTITION BY s_store_name) AS store_total_sales
FROM grouped_sales
ORDER BY total_sales DESC
LIMIT 100
