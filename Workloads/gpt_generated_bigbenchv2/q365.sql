WITH store_rev AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category
),
web_rev AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category
),
review_stats AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(sr.i_category_id, wr.i_category_id, rs.i_category_id) AS category_id,
    COALESCE(sr.i_category, wr.i_category, rs.i_category) AS category_name,
    COALESCE(sr.store_revenue, 0) + COALESCE(wr.web_revenue, 0) AS total_revenue,
    COALESCE(sr.store_customer_cnt, 0) + COALESCE(wr.web_customer_cnt, 0) AS total_customers,
    rs.avg_sentiment,
    rs.review_cnt
FROM store_rev sr
FULL OUTER JOIN web_rev wr
    ON sr.i_category_id = wr.i_category_id
FULL OUTER JOIN review_stats rs
    ON COALESCE(sr.i_category_id, wr.i_category_id) = rs.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
