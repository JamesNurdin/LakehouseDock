WITH purchases AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS spend
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        ws.ws_customer_id AS customer_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS spend
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
customer_reviews AS (
    SELECT
        pr_item_id AS item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    SUM(p.quantity) AS total_quantity,
    SUM(p.spend) AS total_spend,
    CASE
        WHEN SUM(p.quantity) FILTER (WHERE cr.avg_rating IS NOT NULL) = 0 THEN NULL
        ELSE SUM(p.quantity * cr.avg_rating) FILTER (WHERE cr.avg_rating IS NOT NULL) / SUM(p.quantity) FILTER (WHERE cr.avg_rating IS NOT NULL)
    END AS avg_item_rating
FROM purchases p
JOIN customers c ON p.customer_id = c.c_customer_id
LEFT JOIN customer_reviews cr ON p.item_id = cr.item_id
GROUP BY c.c_customer_id, c.c_name
ORDER BY total_spend DESC
LIMIT 10
