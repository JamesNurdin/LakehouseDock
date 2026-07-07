WITH store_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category_name,
        s.s_store_name AS store_name,
        'store' AS channel,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_id, i.i_category, s.s_store_name
),
web_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category_name,
        NULL AS store_name,
        'web' AS channel,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    combined.category_id,
    combined.category_name,
    combined.store_name,
    combined.channel,
    combined.total_quantity,
    combined.total_revenue
FROM (
    SELECT
        category_id,
        category_name,
        store_name,
        channel,
        total_quantity,
        total_revenue
    FROM store_agg
    UNION ALL
    SELECT
        category_id,
        category_name,
        store_name,
        channel,
        total_quantity,
        total_revenue
    FROM web_agg
) AS combined
ORDER BY combined.category_id, combined.channel, combined.store_name
