WITH store_purchases AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        i.i_price AS price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_purchases AS (
    SELECT
        ws.ws_customer_id AS customer_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        i.i_price AS price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
all_purchases AS (
    SELECT customer_id, item_id, quantity, price FROM store_purchases
    UNION ALL
    SELECT customer_id, item_id, quantity, price FROM web_purchases
),
item_ratings AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS rating_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
customer_aggregates AS (
    SELECT
        ap.customer_id,
        SUM(ap.quantity) AS total_quantity,
        SUM(ap.quantity * ap.price) AS total_spent,
        COUNT(DISTINCT ap.item_id) AS distinct_items,
        AVG(ir.avg_rating) AS avg_item_rating,
        SUM(ir.rating_count) AS total_ratings
    FROM all_purchases ap
    LEFT JOIN item_ratings ir ON ap.item_id = ir.item_id
    GROUP BY ap.customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    ca.total_quantity,
    ca.total_spent,
    ca.distinct_items,
    ROUND(ca.avg_item_rating, 2) AS avg_item_rating,
    ca.total_ratings
FROM customer_aggregates ca
JOIN customers c ON ca.customer_id = c.c_customer_id
ORDER BY ca.total_spent DESC
LIMIT 20
