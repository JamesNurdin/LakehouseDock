WITH store_sales_agg AS (
    SELECT i.i_category,
           SUM(ss.ss_quantity) AS total_store_quantity,
           COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
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
SELECT i.i_category,
       COALESCE(ssa.total_store_quantity, 0) + COALESCE(wsa.total_web_quantity, 0) AS total_quantity_sold,
       COALESCE(ssa.distinct_store_customers, 0) + COALESCE(wsa.distinct_web_customers, 0) AS total_distinct_customers,
       COALESCE(ra.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(ra.review_count, 0) AS total_reviews
FROM (
    SELECT DISTINCT i_category FROM items
) i
LEFT JOIN store_sales_agg ssa ON i.i_category = ssa.i_category
LEFT JOIN web_sales_agg wsa ON i.i_category = wsa.i_category
LEFT JOIN review_agg ra ON i.i_category = ra.i_category
ORDER BY total_quantity_sold DESC
LIMIT 20
