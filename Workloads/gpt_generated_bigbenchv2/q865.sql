WITH store_sales_enriched AS (
    SELECT
        ss.ss_transaction_id AS transaction_id,
        ss.ss_customer_id AS customer_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        'Store' AS channel,
        s.s_store_name AS store_name
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_enriched AS (
    SELECT
        ws.ws_transaction_id AS transaction_id,
        ws.ws_customer_id AS customer_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        'Web' AS channel,
        NULL AS store_name
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
all_sales AS (
    SELECT * FROM store_sales_enriched
    UNION ALL
    SELECT * FROM web_sales_enriched
)
SELECT
    i.i_category AS category,
    all_sales.channel,
    SUM(all_sales.quantity) AS total_quantity,
    SUM(all_sales.quantity * i.i_price) AS total_revenue,
    COUNT(DISTINCT all_sales.customer_id) AS distinct_customers,
    COUNT(DISTINCT all_sales.store_name) FILTER (WHERE all_sales.channel = 'Store') AS distinct_stores
FROM all_sales
JOIN items i ON all_sales.item_id = i.i_item_id
GROUP BY
    i.i_category,
    all_sales.channel
ORDER BY
    total_revenue DESC
