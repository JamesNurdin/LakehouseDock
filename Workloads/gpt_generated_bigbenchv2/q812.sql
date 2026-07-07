WITH store_sales_agg AS (
    SELECT i.i_category AS category,
           SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category AS category,
           SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
reviews_agg AS (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    COALESCE(ss.category, ws.category, r.category) AS category,
    COALESCE(ss.store_qty, 0) AS total_store_quantity,
    COALESCE(ws.web_qty, 0) AS total_web_quantity,
    COALESCE(r.avg_sentiment, NULL) AS avg_review_sentiment,
    COALESCE(r.review_count, 0) AS review_count,
    (COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0)) AS total_quantity
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws ON ss.category = ws.category
FULL OUTER JOIN reviews_agg r ON COALESCE(ss.category, ws.category) = r.category
ORDER BY total_quantity DESC
LIMIT 10
