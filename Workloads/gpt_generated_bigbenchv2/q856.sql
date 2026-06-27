WITH store_data AS (
    SELECT
        ss.ss_transaction_id,
        ss.ss_customer_id,
        c.c_name AS customer_name,
        ss.ss_store_id,
        s.s_store_name,
        ss.ss_item_id,
        i.i_name AS item_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        ss.ss_quantity,
        i.i_price * ss.ss_quantity AS revenue,
        'store' AS channel
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_data AS (
    SELECT
        ws.ws_transaction_id,
        ws.ws_customer_id,
        c.c_name AS customer_name,
        NULL AS ss_store_id,
        NULL AS s_store_name,
        ws.ws_item_id,
        i.i_name AS item_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        ws.ws_quantity,
        i.i_price * ws.ws_quantity AS revenue,
        'web' AS channel
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    channel,
    i_category_id,
    i_category_name,
    COUNT(DISTINCT transaction_id) AS total_transactions,
    SUM(quantity) AS total_quantity,
    SUM(revenue) AS total_revenue,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    SUM(revenue) / NULLIF(SUM(quantity), 0) AS avg_price_per_unit
FROM (
    SELECT
        ss_transaction_id AS transaction_id,
        ss_customer_id AS customer_id,
        ss_quantity AS quantity,
        revenue,
        i_category_id,
        i_category_name,
        channel
    FROM store_data
    UNION ALL
    SELECT
        ws_transaction_id AS transaction_id,
        ws_customer_id AS customer_id,
        ws_quantity AS quantity,
        revenue,
        i_category_id,
        i_category_name,
        channel
    FROM web_data
) AS unified_sales
GROUP BY channel, i_category_id, i_category_name
ORDER BY channel, total_revenue DESC
