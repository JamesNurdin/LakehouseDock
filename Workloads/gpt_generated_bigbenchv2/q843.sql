WITH store_sales_data AS (
    SELECT
        i.i_category_name,
        i.i_price,
        ss.ss_quantity AS quantity,
        s.s_store_name,
        'store' AS channel
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_data AS (
    SELECT
        i.i_category_name,
        i.i_price,
        ws.ws_quantity AS quantity,
        NULL AS s_store_name,
        'web' AS channel
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    channel,
    i_category_name,
    SUM(quantity) AS total_quantity,
    SUM(quantity * i_price) AS total_revenue
FROM (
    SELECT * FROM store_sales_data
    UNION ALL
    SELECT * FROM web_sales_data
) AS all_sales
GROUP BY channel, i_category_name
HAVING SUM(quantity * i_price) > 1000
ORDER BY channel, total_revenue DESC
