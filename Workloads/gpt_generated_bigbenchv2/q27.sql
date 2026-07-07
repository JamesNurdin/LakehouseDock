WITH store_sales_data AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_sales_data AS (
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
combined_sales AS (
    SELECT item_id, quantity, customer_id FROM store_sales_data
    UNION ALL
    SELECT item_id, quantity, customer_id FROM web_sales_data
)
SELECT i.i_category_id,
       i.i_category,
       SUM(cs.quantity) AS total_quantity_sold,
       COUNT(DISTINCT cs.customer_id) AS distinct_customers,
       SUM(i.i_price * cs.quantity) AS total_revenue,
       AVG(pr.pr_sentiment) AS avg_sentiment,
       COUNT(pr.pr_review_id) AS review_count
FROM combined_sales cs
JOIN items i ON cs.item_id = i.i_item_id
LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_revenue DESC
LIMIT 10
