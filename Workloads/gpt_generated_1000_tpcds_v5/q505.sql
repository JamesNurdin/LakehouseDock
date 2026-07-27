WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_manager_id,
        regexp_extract(i.i_product_name, '(\\w+ought)', 1) AS extracted_suffix,
        CASE
            WHEN regexp_like(i.i_product_name, '.*able.*') THEN 'ContainsAble'
            ELSE 'Other'
        END AS product_category,
        substring(i.i_product_name, 1, 5) AS name_prefix,
        concat(i.i_product_name, '-mgr', cast(i.i_manager_id as varchar)) AS full_label
    FROM tpcds.item i
    WHERE regexp_like(i.i_product_name, '.*(able|ought)$')
      AND i.i_product_name LIKE '%a%'
)
SELECT
    fm.i_manager_id,
    fm.product_category,
    COUNT(DISTINCT fm.i_item_sk) AS distinct_items,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) AS total_sales,
    MIN(fm.extracted_suffix) AS example_suffix,
    MIN(fm.name_prefix) AS example_prefix,
    MIN(fm.full_label) AS example_label
FROM filtered_items fm
LEFT JOIN tpcds.store_sales ss
    ON ss.ss_item_sk = fm.i_item_sk
LEFT JOIN tpcds.web_sales ws
    ON ws.ws_item_sk = fm.i_item_sk
GROUP BY fm.i_manager_id, fm.product_category
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
