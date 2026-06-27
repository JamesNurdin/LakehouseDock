WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        s.s_store_id,
        s.s_store_name,
        'store' AS channel,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue,
        c.c_customer_id AS customer_id
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        NULL AS s_store_id,
        NULL AS s_store_name,
        'web' AS channel,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue,
        c.c_customer_id AS customer_id
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
combined AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
)
SELECT
    c.i_category_id,
    c.i_category_name,
    COALESCE(c.s_store_name, 'Online') AS store_name,
    c.channel,
    SUM(c.quantity) AS total_quantity,
    SUM(c.revenue) AS total_revenue,
    COUNT(DISTINCT c.customer_id) AS distinct_customers
FROM combined c
GROUP BY
    c.i_category_id,
    c.i_category_name,
    c.s_store_name,
    c.channel
ORDER BY total_revenue DESC
LIMIT 20
