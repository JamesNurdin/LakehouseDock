WITH all_purchases AS (
    SELECT ss_customer_id AS customer_id,
           ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_customer_id AS customer_id,
           ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
item_sentiment AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT c.c_customer_id,
       c.c_name,
       SUM(p.quantity) AS total_quantity,
       AVG(s.avg_sentiment) AS avg_item_sentiment
FROM all_purchases p
JOIN customers c ON p.customer_id = c.c_customer_id
LEFT JOIN item_sentiment s ON p.item_id = s.item_id
GROUP BY c.c_customer_id, c.c_name
ORDER BY total_quantity DESC
LIMIT 10
