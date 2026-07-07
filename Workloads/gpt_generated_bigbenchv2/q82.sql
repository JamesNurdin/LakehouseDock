WITH combined_sales AS (
    SELECT
        i.i_category_id,
        i.i_category,
        'store' AS channel,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        i.i_category_id,
        i.i_category,
        'web' AS channel,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    i_category_id,
    i_category,
    channel,
    SUM(quantity) AS total_quantity,
    SUM(revenue) AS total_revenue
FROM combined_sales
GROUP BY i_category_id, i_category, channel
ORDER BY total_revenue DESC
