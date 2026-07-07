WITH sales AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
sentiment AS (
    SELECT i.i_category_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT COALESCE(s.i_category_id, w.i_category_id) AS category_id,
       COALESCE(s.i_category, w.i_category) AS category_name,
       COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
       COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue,
       sentiment.avg_sentiment
FROM sales s
FULL OUTER JOIN web w ON s.i_category_id = w.i_category_id
LEFT JOIN sentiment ON COALESCE(s.i_category_id, w.i_category_id) = sentiment.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
