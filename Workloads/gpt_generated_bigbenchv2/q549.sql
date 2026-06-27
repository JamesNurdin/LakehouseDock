WITH reviews_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
customer_sales AS (
    SELECT
        ws.ws_customer_id AS customer_id,
        SUM(ws.ws_quantity * i.i_price) AS total_spent,
        COUNT(DISTINCT ws.ws_item_id) AS distinct_items,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_customer_id
),
customer_item_ratings AS (
    SELECT
        ws.ws_customer_id AS customer_id,
        AVG(r.avg_rating) AS avg_rating,
        SUM(r.review_count) AS review_count
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN reviews_agg r ON i.i_item_id = r.item_id
    GROUP BY ws.ws_customer_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    cs.total_spent,
    cs.distinct_items,
    cs.total_quantity,
    COALESCE(cir.avg_rating, 0) AS avg_rating,
    COALESCE(cir.review_count, 0) AS review_count
FROM customers c
JOIN customer_sales cs ON c.c_customer_id = cs.customer_id
LEFT JOIN customer_item_ratings cir ON c.c_customer_id = cir.customer_id
ORDER BY cs.total_spent DESC
LIMIT 10
