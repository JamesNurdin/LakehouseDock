WITH sales AS (
    SELECT
        ss_customer_id AS customer_id,
        ss_item_id AS item_id,
        ss_quantity AS quantity,
        'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT
        ws_customer_id AS customer_id,
        ws_item_id AS item_id,
        ws_quantity AS quantity,
        'web' AS channel
    FROM web_sales
),
item_rating AS (
    SELECT
        pr_item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(pr_review_id) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    SUM(s.quantity) AS total_quantity,
    SUM(CASE WHEN s.channel = 'store' THEN s.quantity ELSE 0 END) AS store_quantity,
    SUM(CASE WHEN s.channel = 'web' THEN s.quantity ELSE 0 END) AS web_quantity,
    SUM(s.quantity * i.i_price) AS total_spend,
    AVG(ir.avg_rating) AS avg_item_rating,
    COUNT(DISTINCT s.item_id) AS distinct_items_purchased,
    SUM(COALESCE(ir.review_count, 0)) AS total_reviews_of_purchased_items
FROM customers c
LEFT JOIN sales s ON s.customer_id = c.c_customer_id
LEFT JOIN items i ON i.i_item_id = s.item_id
LEFT JOIN item_rating ir ON ir.pr_item_id = i.i_item_id
GROUP BY c.c_customer_id, c.c_name
ORDER BY total_spend DESC
LIMIT 20
