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
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT COALESCE(ss.i_category, ws.i_category, r.i_category) AS category,
       COALESCE(ss.store_quantity, 0) AS total_store_quantity,
       COALESCE(ws.web_quantity, 0) AS total_web_quantity,
       r.avg_sentiment AS average_review_sentiment,
       COALESCE(r.review_count, 0) AS review_count
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws ON ss.i_category = ws.i_category
FULL OUTER JOIN review_agg r ON COALESCE(ss.i_category, ws.i_category) = r.i_category
ORDER BY category
