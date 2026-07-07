WITH unified_sales AS (
    SELECT ss_customer_id AS customer_id,
           ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_customer_id AS customer_id,
           ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
)
SELECT c.c_customer_id,
       c.c_name,
       SUM(i.i_price * us.quantity) AS total_spent,
       AVG(pr.pr_sentiment) AS avg_sentiment
FROM unified_sales us
JOIN customers c ON us.customer_id = c.c_customer_id
JOIN items i ON us.item_id = i.i_item_id
LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
GROUP BY c.c_customer_id, c.c_name
ORDER BY total_spent DESC
LIMIT 5
