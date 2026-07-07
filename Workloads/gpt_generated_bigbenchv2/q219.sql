WITH store_agg AS (
    SELECT i.i_category AS category,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_agg AS (
    SELECT i.i_category AS category,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
review_agg AS (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT COALESCE(s.category, w.category, r.category) AS category,
       COALESCE(s.store_quantity, 0) AS store_quantity,
       COALESCE(w.web_quantity, 0) AS web_quantity,
       COALESCE(s.store_revenue, 0) AS store_revenue,
       COALESCE(w.web_revenue, 0) AS web_revenue,
       COALESCE(s.store_customer_count, 0) AS store_customer_count,
       COALESCE(w.web_customer_count, 0) AS web_customer_count,
       COALESCE(r.avg_sentiment, NULL) AS avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count,
       (COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0)) AS total_quantity,
       (COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0)) AS total_revenue
FROM store_agg s
FULL OUTER JOIN web_agg w ON s.category = w.category
FULL OUTER JOIN review_agg r ON COALESCE(s.category, w.category) = r.category
ORDER BY total_revenue DESC
LIMIT 20
