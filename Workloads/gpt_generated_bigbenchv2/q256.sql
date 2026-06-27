WITH combined_sales AS (
    SELECT
        ss_transaction_id AS transaction_id,
        ss_customer_id AS customer_id,
        ss_item_id AS item_id,
        ss_quantity AS quantity,
        ss_ts AS ts,
        'store' AS sales_channel,
        ss_store_id AS store_id
    FROM store_sales
    UNION ALL
    SELECT
        ws_transaction_id AS transaction_id,
        ws_customer_id AS customer_id,
        ws_item_id AS item_id,
        ws_quantity AS quantity,
        ws_ts AS ts,
        'web' AS sales_channel,
        NULL AS store_id
    FROM web_sales
)
SELECT
    c.c_customer_id,
    c.c_name,
    i.i_category_id,
    i.i_category_name,
    SUM(cs.quantity) AS total_quantity,
    SUM(cs.quantity * i.i_price) AS total_revenue,
    COUNT(DISTINCT cs.transaction_id) AS distinct_transactions,
    COUNT(DISTINCT cs.sales_channel) AS sales_channels_used
FROM combined_sales cs
JOIN customers c
    ON cs.customer_id = c.c_customer_id
JOIN items i
    ON cs.item_id = i.i_item_id
GROUP BY
    c.c_customer_id,
    c.c_name,
    i.i_category_id,
    i.i_category_name
ORDER BY total_revenue DESC
LIMIT 20
