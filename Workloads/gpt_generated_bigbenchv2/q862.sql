WITH store_sales_agg AS (
    SELECT ss.ss_item_id,
           SUM(ss.ss_quantity) AS total_store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT ws.ws_item_id,
           SUM(ws.ws_quantity) AS total_web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT pr.pr_item_id,
           COUNT(*) AS review_count,
           SUM(pr.pr_sentiment) AS sum_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(COALESCE(ssa.total_store_quantity, 0)) AS total_store_quantity,
       SUM(COALESCE(wsa.total_web_quantity, 0)) AS total_web_quantity,
       SUM(COALESCE(ssa.total_store_revenue, 0)) AS total_store_revenue,
       SUM(COALESCE(wsa.total_web_revenue, 0)) AS total_web_revenue,
       SUM(COALESCE(ra.review_count, 0)) AS review_count,
       CASE WHEN SUM(COALESCE(ra.review_count, 0)) > 0 THEN
            SUM(COALESCE(ra.sum_sentiment, 0)) / SUM(COALESCE(ra.review_count, 0))
            ELSE NULL
       END AS avg_sentiment
FROM items i
LEFT JOIN store_sales_agg ssa ON ssa.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa ON wsa.ws_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY i.i_category_id
