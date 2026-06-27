WITH sales AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_item_id AS item_id,
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        ss.ss_quantity AS quantity,
        i.i_price * ss.ss_quantity AS revenue,
        c.c_name AS customer_name,
        'store' AS channel
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT
        ws.ws_customer_id AS customer_id,
        ws.ws_item_id AS item_id,
        i.i_category_id AS category_id,
        i.i_category_name AS category_name,
        ws.ws_quantity AS quantity,
        i.i_price * ws.ws_quantity AS revenue,
        c.c_name AS customer_name,
        'web' AS channel
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    sales.customer_name,
    sales.category_name,
    SUM(CASE WHEN sales.channel = 'store' THEN sales.quantity ELSE 0 END) AS store_quantity,
    SUM(CASE WHEN sales.channel = 'web'   THEN sales.quantity ELSE 0 END) AS web_quantity,
    SUM(sales.quantity)                                 AS total_quantity,
    SUM(CASE WHEN sales.channel = 'store' THEN sales.revenue ELSE 0 END) AS store_revenue,
    SUM(CASE WHEN sales.channel = 'web'   THEN sales.revenue ELSE 0 END) AS web_revenue,
    SUM(sales.revenue)                                   AS total_revenue
FROM sales
GROUP BY sales.customer_name, sales.category_name
ORDER BY total_revenue DESC
LIMIT 20
