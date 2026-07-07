WITH store_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT COALESCE(ss.i_category_id, ws.i_category_id, rev.i_category_id) AS category_id,
       COALESCE(ss.i_category, ws.i_category, rev.i_category) AS category_name,
       COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
       COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0) AS total_revenue,
       COALESCE(ss.store_customer_cnt, 0) + COALESCE(ws.web_customer_cnt, 0) AS total_customers,
       rev.avg_sentiment,
       rev.review_cnt
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws ON ss.i_category_id = ws.i_category_id
FULL OUTER JOIN reviews_agg rev ON COALESCE(ss.i_category_id, ws.i_category_id) = rev.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
