WITH
    sampled_items AS (
        SELECT i_item_sk,
               i_item_desc,
               i_category,
               i_product_name,
               i_manager_id
        FROM item
        TABLESAMPLE BERNOULLI (10)
    ),
    sales_agg AS (
        SELECT ws_item_sk,
               SUM(ws_net_profit) AS total_profit,
               SUM(ws_quantity) AS total_qty
        FROM web_sales
        GROUP BY ws_item_sk
    ),
    excluded_items AS (
        SELECT ws_item_sk
        FROM web_sales
        WHERE ws_net_profit > 0
        EXCEPT
        SELECT i_item_sk
        FROM sampled_items
        WHERE i_manager_id = 34
    ),
    joined AS (
        SELECT
            si.i_item_sk,
            si.i_category,
            si.i_product_name,
            si.i_item_desc,
            sa.total_profit,
            sa.total_qty
        FROM sampled_items si
        FULL OUTER JOIN sales_agg sa
            ON si.i_item_sk = sa.ws_item_sk
    )
SELECT
    j.i_category,
    CONCAT(j.i_category, ':', j.i_product_name) AS category_product,
    regexp_extract(j.i_item_desc, '(\\d{4})', 1) AS extracted_year,
    prod.short_name,
    j.total_profit,
    j.total_qty,
    (SELECT AVG(ws_net_profit) FROM web_sales) AS avg_profit,
    CASE WHEN EXISTS (
        SELECT 1 FROM web_sales ws2
        WHERE ws2.ws_item_sk = j.i_item_sk
          AND ws2.ws_net_paid > 500
    ) THEN 1 ELSE 0 END AS high_paid_exists
FROM joined j
CROSS JOIN LATERAL (
    SELECT substr(j.i_product_name, 1, 5) AS short_name
) prod
WHERE
    regexp_like(j.i_item_desc, '[A-Za-z]{3,}\\s[0-9]{4}')
    AND j.i_product_name LIKE '%Shirt%'
    AND j.i_item_sk IS NOT NULL
    AND j.i_item_sk NOT IN (SELECT ws_item_sk FROM excluded_items)
ORDER BY j.total_profit DESC
LIMIT 100
