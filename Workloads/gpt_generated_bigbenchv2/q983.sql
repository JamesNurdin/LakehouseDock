WITH unified_sales AS (
    SELECT ss.ss_customer_id AS customer_id,
           ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_customer_id AS customer_id,
           ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity
    FROM web_sales ws
),
sales_with_price AS (
    SELECT us.customer_id,
           us.item_id,
           us.quantity,
           i.i_price AS i_price
    FROM unified_sales us
    JOIN items i ON i.i_item_id = us.item_id
),
reviews AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    SUM(swp.quantity) AS total_quantity,
    SUM(swp.quantity * swp.i_price) AS total_spend,
    AVG(r.avg_sentiment) AS avg_item_sentiment
FROM customers c
JOIN sales_with_price swp ON swp.customer_id = c.c_customer_id
LEFT JOIN reviews r ON r.item_id = swp.item_id
GROUP BY c.c_customer_id, c.c_name
ORDER BY total_spend DESC
LIMIT 10
