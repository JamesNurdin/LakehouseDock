WITH store_sales_agg AS (
    SELECT i.i_category AS category,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category AS category,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
sales_agg AS (
    SELECT COALESCE(s.category, w.category) AS category,
           COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
    FROM store_sales_agg s
    FULL OUTER JOIN web_sales_agg w ON s.category = w.category
),
review_agg AS (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT s.category,
       s.total_quantity,
       r.avg_sentiment,
       r.review_count
FROM sales_agg s
JOIN review_agg r ON s.category = r.category
ORDER BY s.total_quantity DESC
LIMIT 10
