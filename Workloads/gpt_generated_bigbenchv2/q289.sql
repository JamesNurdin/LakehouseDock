WITH store_sales_agg AS (
    SELECT s.s_store_id,
           s.s_store_name,
           i.i_category AS i_category,
           SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category AS i_category,
           SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_agg AS (
    SELECT i.i_category AS i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT ss.s_store_name,
       ss.i_category,
       ss.total_store_quantity,
       COALESCE(ws.total_web_quantity, 0) AS total_web_quantity,
       rev.avg_sentiment,
       rev.review_count
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws ON ss.i_category = ws.i_category
LEFT JOIN review_agg rev ON ss.i_category = rev.i_category
ORDER BY ss.s_store_name, ss.i_category
