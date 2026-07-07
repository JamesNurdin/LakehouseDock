WITH store_agg AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        i.i_category AS category,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        'store' AS channel
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category
),
web_agg AS (
    SELECT
        NULL AS store_id,
        NULL AS store_name,
        i.i_category AS category,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue,
        'web' AS channel
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    store_id,
    store_name,
    category,
    total_quantity,
    total_revenue,
    channel
FROM store_agg
UNION ALL
SELECT
    store_id,
    store_name,
    category,
    total_quantity,
    total_revenue,
    channel
FROM web_agg
ORDER BY channel, store_name, category
