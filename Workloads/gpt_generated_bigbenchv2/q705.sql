WITH store_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS store_qty,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS web_qty,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_sent AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
category_sales AS (
    SELECT COALESCE(s.i_category_id, w.i_category_id) AS i_category_id,
           COALESCE(s.i_category, w.i_category) AS i_category,
           COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_quantity,
           COALESCE(s.store_customers, 0) + COALESCE(w.web_customers, 0) AS total_customers
    FROM store_sales_agg s
    FULL OUTER JOIN web_sales_agg w
        ON s.i_category_id = w.i_category_id
)
SELECT r.i_category_id,
       r.i_category,
       cs.total_quantity,
       cs.total_customers,
       r.avg_sentiment,
       r.review_cnt
FROM review_sent r
LEFT JOIN category_sales cs
    ON r.i_category_id = cs.i_category_id
ORDER BY cs.total_quantity DESC
LIMIT 10
