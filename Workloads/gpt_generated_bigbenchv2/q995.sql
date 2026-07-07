WITH combined_sales AS (
    SELECT ss.ss_customer_id AS customer_id,
           ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_customer_id AS customer_id,
           ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity
    FROM web_sales ws
)
SELECT i.i_category,
       i.i_category_id,
       COUNT(DISTINCT cs.customer_id) AS distinct_customers,
       SUM(cs.quantity) AS total_quantity_sold,
       AVG(pr.pr_sentiment) AS avg_sentiment,
       COUNT(pr.pr_review_id) AS review_count
FROM combined_sales cs
JOIN items i ON cs.item_id = i.i_item_id
LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
