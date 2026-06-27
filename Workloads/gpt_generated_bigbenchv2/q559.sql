WITH purchases AS (
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
customer_purchases AS (
    SELECT
        p.customer_id,
        SUM(p.quantity) AS total_quantity,
        COUNT(DISTINCT p.item_id) AS distinct_items,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM purchases p
    JOIN customers c ON c.c_customer_id = p.customer_id
    JOIN items i ON i.i_item_id = p.item_id
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY p.customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    cp.total_quantity,
    cp.distinct_items,
    cp.avg_rating,
    cp.review_count
FROM customer_purchases cp
JOIN customers c ON c.c_customer_id = cp.customer_id
ORDER BY cp.total_quantity DESC
LIMIT 20
