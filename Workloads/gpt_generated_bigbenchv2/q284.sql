WITH item_ratings AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
item_web_sales AS (
    SELECT i.i_item_id,
           SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_agg AS (
    SELECT ss.ss_store_id,
           SUM(ss.ss_quantity) AS total_store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
           COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers,
           SUM(ss.ss_quantity * COALESCE(ir.avg_rating, 0)) / NULLIF(SUM(ss.ss_quantity), 0) AS weighted_avg_item_rating
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
    GROUP BY ss.ss_store_id
),
store_items AS (
    SELECT DISTINCT ss.ss_store_id,
           ss.ss_item_id AS i_item_id
    FROM store_sales ss
),
store_web_sales_agg AS (
    SELECT si.ss_store_id,
           SUM(COALESCE(iws.total_web_quantity, 0)) AS total_web_quantity_for_store_items
    FROM store_items si
    LEFT JOIN item_web_sales iws ON si.i_item_id = iws.i_item_id
    GROUP BY si.ss_store_id
)
SELECT s.s_store_id,
       s.s_store_name,
       sa.total_store_quantity,
       sa.total_store_revenue,
       sa.distinct_store_customers,
       sa.weighted_avg_item_rating,
       sw.total_web_quantity_for_store_items
FROM store_sales_agg sa
JOIN stores s ON sa.ss_store_id = s.s_store_id
LEFT JOIN store_web_sales_agg sw ON sa.ss_store_id = sw.ss_store_id
ORDER BY sa.total_store_revenue DESC
LIMIT 10
