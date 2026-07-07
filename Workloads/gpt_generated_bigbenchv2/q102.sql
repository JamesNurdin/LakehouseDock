WITH review_stats AS (
    SELECT pr_item_id AS i_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
store_sales_agg AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS total_store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS total_web_quantity
    FROM web_sales
    GROUP BY ws_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       rs.avg_sentiment,
       rs.review_count,
       COALESCE(ss.total_store_quantity, 0) AS total_store_quantity,
       COALESCE(ws.total_web_quantity, 0) AS total_web_quantity,
       (COALESCE(ss.total_store_quantity, 0) + COALESCE(ws.total_web_quantity, 0)) AS total_quantity_sold,
       (COALESCE(ss.total_store_quantity, 0) + COALESCE(ws.total_web_quantity, 0)) * i.i_price AS total_revenue
FROM items i
LEFT JOIN review_stats rs ON i.i_item_id = rs.i_item_id
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.i_item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.i_item_id
WHERE i.i_category IS NOT NULL
ORDER BY total_revenue DESC
LIMIT 10
