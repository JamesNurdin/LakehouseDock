WITH store_sales_agg AS (
    SELECT i.i_category AS category,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    INNER JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category AS category,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    INNER JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
reviews_agg AS (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    INNER JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT COALESCE(ss.category, ws.category, rev.category) AS category,
       COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
       rev.avg_sentiment,
       rev.review_count
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws ON ss.category = ws.category
FULL OUTER JOIN reviews_agg rev ON COALESCE(ss.category, ws.category) = rev.category
ORDER BY total_quantity DESC
