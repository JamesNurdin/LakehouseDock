WITH store_purchases AS (
    SELECT ss.ss_customer_id AS customer_id,
           ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           i.i_price AS price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_purchases AS (
    SELECT ws.ws_customer_id AS customer_id,
           ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           i.i_price AS price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
all_purchases AS (
    SELECT * FROM store_purchases
    UNION ALL
    SELECT * FROM web_purchases
),
item_review AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT c.c_customer_id,
       c.c_name,
       SUM(p.quantity) AS total_quantity,
       SUM(p.quantity * p.price) AS total_spend,
       AVG(ir.avg_sentiment) AS avg_review_sentiment
FROM customers c
JOIN all_purchases p ON c.c_customer_id = p.customer_id
LEFT JOIN item_review ir ON p.item_id = ir.item_id
GROUP BY c.c_customer_id, c.c_name
ORDER BY total_spend DESC
LIMIT 10
