WITH combined_sales AS (
    SELECT
        ss_transaction_id AS transaction_id,
        ss_customer_id AS customer_id,
        ss_item_id AS item_id,
        ss_store_id AS store_id,
        ss_quantity AS quantity,
        ss_ts AS ts,
        'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT
        ws_transaction_id AS transaction_id,
        ws_customer_id AS customer_id,
        ws_item_id AS item_id,
        NULL AS store_id,
        ws_quantity AS quantity,
        ws_ts AS ts,
        'web' AS channel
    FROM web_sales
)
SELECT
    cs.channel,
    COALESCE(s.s_store_name, 'Online') AS store_name,
    i.i_category AS item_category,
    SUM(cs.quantity) AS total_quantity,
    SUM(cs.quantity * i.i_price) AS total_revenue
FROM combined_sales cs
JOIN items i ON cs.item_id = i.i_item_id
LEFT JOIN stores s ON cs.store_id = s.s_store_id
GROUP BY cs.channel, COALESCE(s.s_store_name, 'Online'), i.i_category
ORDER BY cs.channel, total_revenue DESC
