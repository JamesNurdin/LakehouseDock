WITH store_sales_agg AS (
    SELECT i.i_category,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_sales_agg AS (
    SELECT i.i_category,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
),
reviews_agg AS (
    SELECT i.i_category,
           COUNT(pr.pr_review_id) AS review_count,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT COALESCE(s.i_category, w.i_category, r.i_category) AS category,
       COALESCE(s.store_quantity, 0) AS total_store_quantity,
       COALESCE(w.web_quantity, 0) AS total_web_quantity,
       COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
       COALESCE(r.review_count, 0) AS review_count,
       r.avg_sentiment
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w ON s.i_category = w.i_category
FULL OUTER JOIN reviews_agg r ON COALESCE(s.i_category, w.i_category) = r.i_category
ORDER BY total_quantity DESC
LIMIT 10
