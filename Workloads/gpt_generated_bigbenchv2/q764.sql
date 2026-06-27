WITH all_sales AS (
    SELECT
        ss_transaction_id AS transaction_id,
        ss_customer_id AS customer_id,
        ss_item_id AS item_id,
        ss_quantity AS quantity,
        'store' AS channel,
        ss_ts AS ts
    FROM store_sales
    UNION ALL
    SELECT
        ws_transaction_id AS transaction_id,
        ws_customer_id AS customer_id,
        ws_item_id AS item_id,
        ws_quantity AS quantity,
        'web' AS channel,
        ws_ts AS ts
    FROM web_sales
)
SELECT
    c.c_customer_id,
    c.c_name,
    i.i_category_id,
    i.i_category_name,
    SUM(all_sales.quantity) AS total_quantity,
    SUM(all_sales.quantity * i.i_price) AS total_revenue,
    SUM(CASE WHEN all_sales.channel = 'store' THEN all_sales.quantity ELSE 0 END) AS store_quantity,
    SUM(CASE WHEN all_sales.channel = 'web' THEN all_sales.quantity ELSE 0 END) AS web_quantity,
    SUM(CASE WHEN all_sales.channel = 'store' THEN all_sales.quantity * i.i_price ELSE 0 END) AS store_revenue,
    SUM(CASE WHEN all_sales.channel = 'web' THEN all_sales.quantity * i.i_price ELSE 0 END) AS web_revenue,
    COUNT(DISTINCT all_sales.transaction_id) AS distinct_transactions
FROM all_sales
JOIN customers c
    ON all_sales.customer_id = c.c_customer_id
JOIN items i
    ON all_sales.item_id = i.i_item_id
GROUP BY
    c.c_customer_id,
    c.c_name,
    i.i_category_id,
    i.i_category_name
ORDER BY total_revenue DESC
LIMIT 100
