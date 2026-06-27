WITH sales AS (
    SELECT
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        i.i_price AS price,
        ss.ss_customer_id AS customer_id,
        ss.ss_store_id AS store_id,
        'store' AS channel
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        i.i_price AS price,
        ws.ws_customer_id AS customer_id,
        NULL AS store_id,
        'web' AS channel
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),

item_sales AS (
    SELECT
        s.item_id,
        SUM(s.quantity) AS total_quantity,
        SUM(s.quantity * s.price) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS distinct_customers,
        COUNT(*) AS total_transactions
    FROM sales s
    GROUP BY s.item_id
),

item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)

SELECT
    i.i_name,
    i.i_category_name,
    isales.total_quantity,
    isales.total_revenue,
    isales.distinct_customers,
    ir.avg_rating,
    ir.review_count
FROM item_sales isales
JOIN items i ON isales.item_id = i.i_item_id
LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
ORDER BY isales.total_revenue DESC
LIMIT 10
