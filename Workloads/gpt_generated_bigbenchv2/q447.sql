WITH store_sales_agg AS (
    SELECT i.i_item_id AS i_item_id,
           SUM(ss.ss_quantity) AS store_quantity,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_sales_agg AS (
    SELECT i.i_item_id AS i_item_id,
           SUM(ws.ws_quantity) AS web_quantity,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
review_agg AS (
    SELECT i.i_item_id AS i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0) AS total_quantity_sold,
       COALESCE(ssa.store_customers, 0) + COALESCE(wsa.web_customers, 0) AS total_customers,
       ra.avg_sentiment,
       ra.review_count
FROM items i
LEFT JOIN store_sales_agg ssa ON ssa.i_item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa ON wsa.i_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.i_item_id = i.i_item_id
WHERE i.i_category IS NOT NULL
ORDER BY total_quantity_sold DESC
LIMIT 100
