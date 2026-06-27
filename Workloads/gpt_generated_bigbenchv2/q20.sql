WITH store_agg AS (
    SELECT
        i.i_category_name,
        s.s_store_name,
        'store' AS channel,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_sales_amount
    FROM store_sales ss
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_name, s.s_store_name
),
web_agg AS (
    SELECT
        i.i_category_name,
        CAST(NULL AS varchar) AS s_store_name,
        'web' AS channel,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_sales_amount
    FROM web_sales ws
    JOIN customers c
        ON ws.ws_customer_id = c.c_customer_id
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_name
)
SELECT
    i_category_name,
    s_store_name,
    channel,
    total_quantity,
    total_sales_amount
FROM (
    SELECT i_category_name, s_store_name, channel, total_quantity, total_sales_amount
    FROM store_agg
    UNION ALL
    SELECT i_category_name, s_store_name, channel, total_quantity, total_sales_amount
    FROM web_agg
) AS combined
ORDER BY i_category_name, channel, total_sales_amount DESC
