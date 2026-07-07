WITH sales_union AS (
    SELECT
        i.i_category,
        'store' AS channel,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    UNION ALL
    SELECT
        i.i_category,
        'web' AS channel,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
)
SELECT
    i_category AS category,
    channel,
    SUM(quantity) AS total_quantity,
    SUM(revenue) AS total_revenue
FROM sales_union
GROUP BY i_category, channel
ORDER BY i_category, channel
