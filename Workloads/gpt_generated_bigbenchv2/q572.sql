WITH store_sales_enriched AS (
    SELECT
        ss.ss_transaction_id AS transaction_id,
        ss.ss_customer_id,
        c.c_name AS customer_name,
        ss.ss_store_id,
        s.s_store_name AS store_name,
        ss.ss_item_id,
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity,
        i.i_price,
        ss.ss_quantity * i.i_price AS revenue,
        'Store' AS channel,
        ss.ss_ts AS ts
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_enriched AS (
    SELECT
        ws.ws_transaction_id AS transaction_id,
        ws.ws_customer_id AS ss_customer_id,
        c.c_name AS customer_name,
        NULL AS ss_store_id,
        NULL AS store_name,
        ws.ws_item_id AS ss_item_id,
        i.i_category_id,
        i.i_category_name,
        ws.ws_quantity AS ss_quantity,
        i.i_price,
        ws.ws_quantity * i.i_price AS revenue,
        'Web' AS channel,
        ws.ws_ts AS ts
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
combined_sales AS (
    SELECT * FROM store_sales_enriched
    UNION ALL
    SELECT * FROM web_sales_enriched
)
SELECT
    cs.customer_name,
    cs.i_category_name,
    cs.channel,
    SUM(cs.ss_quantity) AS total_quantity,
    SUM(cs.revenue) AS total_revenue
FROM combined_sales cs
GROUP BY
    cs.customer_name,
    cs.i_category_name,
    cs.channel
HAVING SUM(cs.revenue) > 1000
ORDER BY total_revenue DESC
LIMIT 100
