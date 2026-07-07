WITH combined_sales AS (
    SELECT ss.ss_transaction_id AS transaction_id,
           ss.ss_customer_id AS customer_id,
           ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_transaction_id AS transaction_id,
           ws.ws_customer_id AS customer_id,
           ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales ws
)
SELECT i.i_category_id,
       i.i_category,
       cs.channel,
       SUM(cs.quantity) AS total_quantity_sold,
       COUNT(DISTINCT cs.customer_id) AS distinct_customers,
       AVG(pr.pr_sentiment) AS avg_sentiment,
       MIN(i.i_price) AS min_price,
       MAX(i.i_price) AS max_price
FROM combined_sales cs
JOIN items i ON cs.item_id = i.i_item_id
LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
GROUP BY i.i_category_id, i.i_category, cs.channel
ORDER BY total_quantity_sold DESC
LIMIT 10
