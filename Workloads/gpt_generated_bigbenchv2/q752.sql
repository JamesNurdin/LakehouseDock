WITH store_sales_agg AS (
    SELECT i.i_category AS category,
           i.i_category_id AS category_id,
           SUM(ss.ss_quantity) AS total_store_quantity,
           COUNT(DISTINCT ss.ss_transaction_id) AS store_txns
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
),
web_sales_agg AS (
    SELECT i.i_category AS category,
           i.i_category_id AS category_id,
           SUM(ws.ws_quantity) AS total_web_quantity,
           COUNT(DISTINCT ws.ws_transaction_id) AS web_txns
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
),
review_agg AS (
    SELECT i.i_category AS category,
           i.i_category_id AS category_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
)
SELECT COALESCE(ss.category, ws.category, r.category) AS category,
       COALESCE(ss.category_id, ws.category_id, r.category_id) AS category_id,
       COALESCE(ss.total_store_quantity, 0) AS total_store_quantity,
       COALESCE(ws.total_web_quantity, 0) AS total_web_quantity,
       COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count
FROM store_sales_agg ss
FULL JOIN web_sales_agg ws ON ss.category_id = ws.category_id
FULL JOIN review_agg r ON COALESCE(ss.category_id, ws.category_id) = r.category_id
ORDER BY category
