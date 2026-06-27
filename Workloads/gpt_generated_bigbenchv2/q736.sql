WITH unified_sales AS (
    SELECT
        ss_transaction_id AS transaction_id,
        ss_customer_id AS customer_id,
        ss_store_id AS store_id,
        ss_item_id AS item_id,
        ss_quantity AS quantity,
        ss_ts AS ts,
        'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT
        ws_transaction_id AS transaction_id,
        ws_customer_id AS customer_id,
        NULL AS store_id,
        ws_item_id AS item_id,
        ws_quantity AS quantity,
        ws_ts AS ts,
        'web' AS channel
    FROM web_sales
)
SELECT
    COALESCE(s.s_store_name, 'Online') AS store_name,
    i.i_category_name,
    SUM(u.quantity) AS total_quantity,
    SUM(u.quantity * i.i_price) AS total_revenue,
    COUNT(DISTINCT u.customer_id) AS distinct_customers,
    COUNT(DISTINCT CASE WHEN u.channel = 'store' THEN u.store_id END) AS distinct_physical_stores
FROM unified_sales u
JOIN customers c
    ON u.customer_id = c.c_customer_id
JOIN items i
    ON u.item_id = i.i_item_id
LEFT JOIN stores s
    ON u.store_id = s.s_store_id
GROUP BY
    COALESCE(s.s_store_name, 'Online'),
    i.i_category_name
ORDER BY total_revenue DESC
LIMIT 20
