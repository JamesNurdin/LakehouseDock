/*
Goal: Identify the top 20 customers by total spend across store and web channels, and show the average sentiment of product reviews for the items they purchased.
*/
WITH store_purchases AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_quantity AS quantity,
        i.i_price AS price,
        pr.pr_sentiment AS sentiment
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
),
web_purchases AS (
    SELECT
        ws.ws_customer_id AS customer_id,
        ws.ws_quantity AS quantity,
        i.i_price AS price,
        pr.pr_sentiment AS sentiment
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
),
all_purchases AS (
    SELECT customer_id, quantity, price, sentiment FROM store_purchases
    UNION ALL
    SELECT customer_id, quantity, price, sentiment FROM web_purchases
)
SELECT
    c.c_name,
    SUM(ap.quantity) AS total_quantity,
    SUM(ap.quantity * ap.price) AS total_spent,
    AVG(ap.sentiment) AS avg_review_sentiment,
    COUNT(*) AS purchase_count
FROM all_purchases ap
JOIN customers c ON ap.customer_id = c.c_customer_id
GROUP BY c.c_name
ORDER BY total_spent DESC
LIMIT 20
