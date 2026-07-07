WITH store_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT COALESCE(ss.i_category_id, ws.i_category_id, rev.i_category_id) AS category_id,
       COALESCE(ss.i_category, ws.i_category, rev.i_category) AS category_name,
       COALESCE(ss.total_store_quantity, 0) + COALESCE(ws.total_web_quantity, 0) AS total_quantity_sold,
       COALESCE(ss.total_store_quantity, 0) AS store_quantity,
       COALESCE(ws.total_web_quantity, 0) AS web_quantity,
       rev.avg_sentiment,
       rev.review_count
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws ON ss.i_category_id = ws.i_category_id
FULL OUTER JOIN reviews_agg rev ON COALESCE(ss.i_category_id, ws.i_category_id) = rev.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 20
