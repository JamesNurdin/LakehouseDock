WITH store_sales_agg AS (
    SELECT i.i_category,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_agg AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT COALESCE(ssa.i_category, wsa.i_category, ra.i_category) AS category,
       COALESCE(ssa.store_quantity, 0) AS store_quantity,
       COALESCE(wsa.web_quantity, 0) AS web_quantity,
       COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0) AS total_quantity,
       ra.avg_sentiment,
       ra.review_count
FROM store_sales_agg ssa
FULL OUTER JOIN web_sales_agg wsa ON ssa.i_category = wsa.i_category
FULL OUTER JOIN review_agg ra ON COALESCE(ssa.i_category, wsa.i_category) = ra.i_category
ORDER BY total_quantity DESC
LIMIT 10
