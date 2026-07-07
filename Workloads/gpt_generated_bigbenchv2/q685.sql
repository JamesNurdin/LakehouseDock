WITH store_sales_agg AS (
    SELECT i.i_category,
           s.s_store_name,
           SUM(ss.ss_quantity) AS total_store_quantity,
           COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category, s.s_store_name
),
web_sales_agg AS (
    SELECT i.i_category,
           SUM(ws.ws_quantity) AS total_web_quantity,
           COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
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
SELECT
    ss_a.i_category,
    ss_a.s_store_name,
    ss_a.total_store_quantity,
    ws_a.total_web_quantity,
    rev_a.avg_sentiment,
    rev_a.review_count,
    ss_a.distinct_store_customers,
    ws_a.distinct_web_customers
FROM store_sales_agg ss_a
LEFT JOIN web_sales_agg ws_a ON ss_a.i_category = ws_a.i_category
LEFT JOIN review_agg rev_a ON ss_a.i_category = rev_a.i_category
ORDER BY ss_a.total_store_quantity DESC
LIMIT 20
