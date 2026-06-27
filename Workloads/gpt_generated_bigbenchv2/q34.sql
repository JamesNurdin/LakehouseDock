WITH combined_sales AS (
    SELECT
        ss_transaction_id AS transaction_id,
        ss_customer_id AS customer_id,
        ss_item_id AS item_id,
        ss_quantity AS quantity,
        ss_ts AS ts,
        'store' AS channel,
        ss_store_id AS store_id
    FROM store_sales
    UNION ALL
    SELECT
        ws_transaction_id AS transaction_id,
        ws_customer_id AS customer_id,
        ws_item_id AS item_id,
        ws_quantity AS quantity,
        ws_ts AS ts,
        'web' AS channel,
        NULL AS store_id
    FROM web_sales
),
sales_with_details AS (
    SELECT
        cs.transaction_id,
        cs.customer_id,
        c.c_name AS customer_name,
        cs.item_id,
        i.i_name AS item_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        cs.quantity,
        cs.channel,
        cs.store_id,
        s.s_store_name AS store_name
    FROM combined_sales cs
    LEFT JOIN customers c
        ON cs.customer_id = c.c_customer_id
    LEFT JOIN items i
        ON cs.item_id = i.i_item_id
    LEFT JOIN stores s
        ON cs.store_id = s.s_store_id
)
SELECT
    COALESCE(swd.store_name, 'Online') AS store,
    swd.channel,
    swd.i_category_name AS category,
    SUM(swd.quantity) AS total_quantity,
    SUM(swd.quantity * swd.i_price) AS total_revenue,
    COUNT(DISTINCT swd.customer_id) AS distinct_customers,
    ROUND(AVG(swd.i_price), 2) AS avg_item_price
FROM sales_with_details swd
GROUP BY
    COALESCE(swd.store_name, 'Online'),
    swd.channel,
    swd.i_category_name
ORDER BY total_revenue DESC
LIMIT 20
