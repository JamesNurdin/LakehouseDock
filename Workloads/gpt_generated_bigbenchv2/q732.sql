WITH store_channel AS (
    SELECT
        'store' AS sales_channel,
        i.i_category AS category,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_channel AS (
    SELECT
        'web' AS sales_channel,
        i.i_category AS category,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
)
SELECT
    sales_channel,
    category,
    SUM(quantity) AS total_quantity,
    SUM(revenue) AS total_revenue
FROM (
    SELECT sales_channel, category, quantity, revenue FROM store_channel
    UNION ALL
    SELECT sales_channel, category, quantity, revenue FROM web_channel
) AS combined
GROUP BY sales_channel, category
ORDER BY total_revenue DESC
