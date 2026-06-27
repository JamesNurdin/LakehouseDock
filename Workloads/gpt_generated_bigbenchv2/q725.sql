WITH sales_union AS (
    SELECT
        ss.ss_transaction_id AS transaction_id,
        ss.ss_customer_id AS customer_id,
        ss.ss_store_id AS store_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        'store' AS sales_channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_transaction_id AS transaction_id,
        ws.ws_customer_id AS customer_id,
        NULL AS store_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        'web' AS sales_channel
    FROM web_sales ws
),
item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(CAST(pr.pr_rating AS double)) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    COALESCE(st.s_store_name, 'Online') AS store_name,
    i.i_category_name,
    COUNT(DISTINCT su.customer_id) AS distinct_customers,
    SUM(su.quantity) AS total_quantity,
    SUM(i.i_price * su.quantity) AS total_revenue,
    AVG(ir.avg_rating) AS avg_item_rating,
    SUM(ir.review_count) AS total_reviews
FROM sales_union su
JOIN items i ON i.i_item_id = su.item_id
LEFT JOIN stores st ON st.s_store_id = su.store_id
LEFT JOIN item_ratings ir ON ir.i_item_id = i.i_item_id
GROUP BY
    COALESCE(st.s_store_name, 'Online'),
    i.i_category_name
ORDER BY total_revenue DESC
LIMIT 20
