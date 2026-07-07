WITH combined_sales AS (
    SELECT
        i.i_category_id,
        i.i_category,
        c.c_customer_id,
        c.c_name,
        ss.ss_quantity AS quantity,
        (ss.ss_quantity * i.i_price) AS revenue,
        'store' AS channel
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT
        i.i_category_id,
        i.i_category,
        c.c_customer_id,
        c.c_name,
        ws.ws_quantity AS quantity,
        (ws.ws_quantity * i.i_price) AS revenue,
        'web' AS channel
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    cs.i_category_id,
    cs.i_category,
    cs.c_customer_id,
    cs.c_name,
    cs.channel,
    SUM(cs.quantity) AS total_quantity,
    SUM(cs.revenue) AS total_revenue
FROM combined_sales cs
GROUP BY cs.i_category_id, cs.i_category, cs.c_customer_id, cs.c_name, cs.channel
ORDER BY cs.i_category_id, cs.c_customer_id, cs.channel
