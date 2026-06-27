WITH item_category_ratings AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(pr.pr_rating)      AS avg_rating,
           AVG(i.i_price)         AS avg_price
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
store_sales_agg AS (
    SELECT ss.ss_store_id,
           i.i_category_id,
           i.i_category_name,
           SUM(ss.ss_quantity)                AS store_quantity,
           COUNT(DISTINCT ss.ss_customer_id)   AS store_distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ws.ws_quantity)               AS web_quantity,
           COUNT(DISTINCT ws.ws_customer_id) AS web_distinct_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT s.s_store_name,
       ssa.i_category_name,
       ssa.store_quantity,
       ssa.store_distinct_customers,
       COALESCE(wsa.web_quantity, 0)               AS web_quantity,
       COALESCE(wsa.web_distinct_customers, 0)     AS web_distinct_customers,
       cat.avg_rating,
       cat.avg_price
FROM store_sales_agg ssa
JOIN stores s ON s.s_store_id = ssa.ss_store_id
JOIN item_category_ratings cat ON ssa.i_category_id = cat.i_category_id
LEFT JOIN web_sales_agg wsa ON cat.i_category_id = wsa.i_category_id
ORDER BY s.s_store_name, ssa.i_category_name
