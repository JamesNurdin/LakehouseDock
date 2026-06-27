WITH
    store_sales_enriched AS (
        SELECT
            ss.ss_transaction_id,
            ss.ss_customer_id,
            c.c_name,
            ss.ss_item_id,
            i.i_name,
            i.i_category_id,
            i.i_category_name,
            i.i_price,
            ss.ss_quantity,
            ss.ss_quantity * i.i_price AS ss_revenue
        FROM store_sales ss
        JOIN customers c ON ss.ss_customer_id = c.c_customer_id
        JOIN items i ON ss.ss_item_id = i.i_item_id
    ),
    web_sales_enriched AS (
        SELECT
            ws.ws_transaction_id,
            ws.ws_customer_id,
            c.c_name,
            ws.ws_item_id,
            i.i_name,
            i.i_category_id,
            i.i_category_name,
            i.i_price,
            ws.ws_quantity,
            ws.ws_quantity * i.i_price AS ws_revenue
        FROM web_sales ws
        JOIN customers c ON ws.ws_customer_id = c.c_customer_id
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ),
    combined_sales AS (
        SELECT
            ss_transaction_id AS transaction_id,
            ss_customer_id AS customer_id,
            c_name,
            ss_item_id AS item_id,
            i_name,
            i_category_id,
            i_category_name,
            i_price,
            ss_quantity AS quantity,
            ss_revenue AS revenue,
            'store' AS channel
        FROM store_sales_enriched
        UNION ALL
        SELECT
            ws_transaction_id AS transaction_id,
            ws_customer_id AS customer_id,
            c_name,
            ws_item_id AS item_id,
            i_name,
            i_category_id,
            i_category_name,
            i_price,
            ws_quantity AS quantity,
            ws_revenue AS revenue,
            'web' AS channel
        FROM web_sales_enriched
    )
SELECT
    c_name AS customer_name,
    i_category_name AS category_name,
    SUM(quantity) AS total_quantity,
    SUM(revenue) AS total_revenue,
    COUNT(DISTINCT transaction_id) AS distinct_transactions,
    COUNT(DISTINCT CASE WHEN channel = 'store' THEN transaction_id END) AS store_transactions,
    COUNT(DISTINCT CASE WHEN channel = 'web' THEN transaction_id END) AS web_transactions
FROM combined_sales
GROUP BY c_name, i_category_name
ORDER BY total_revenue DESC
LIMIT 10
