WITH store_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS store_quantity,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS web_quantity,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT COALESCE(s.i_category, w.i_category, r.i_category) AS category,
       COALESCE(s.store_quantity, 0) AS store_quantity,
       COALESCE(w.web_quantity, 0) AS web_quantity,
       COALESCE(s.store_customer_count, 0) + COALESCE(w.web_customer_count, 0) AS total_customer_count,
       COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count,
       (COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0)) AS total_quantity
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w
    ON s.i_category_id = w.i_category_id
FULL OUTER JOIN reviews_agg r
    ON COALESCE(s.i_category_id, w.i_category_id) = r.i_category_id
ORDER BY total_quantity DESC
