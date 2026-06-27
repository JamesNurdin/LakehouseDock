WITH unified_sales AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        i.i_price AS price,
        i.i_category_name AS category_name,
        s.s_store_name AS store_name,
        'store' AS channel
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_cte AS (
    SELECT
        ws.ws_customer_id AS customer_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        i.i_price AS price,
        i.i_category_name AS category_name,
        NULL AS store_name,
        'web' AS channel
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    us.category_name,
    us.channel,
    SUM(us.quantity) AS total_quantity,
    SUM(us.quantity * us.price) AS total_revenue,
    MAX(us.store_name) AS store_name
FROM (
    SELECT
        customer_id,
        item_id,
        quantity,
        price,
        category_name,
        store_name,
        channel
    FROM unified_sales
    UNION ALL
    SELECT
        customer_id,
        item_id,
        quantity,
        price,
        category_name,
        store_name,
        channel
    FROM web_sales_cte
) us
JOIN customers c ON us.customer_id = c.c_customer_id
GROUP BY c.c_customer_id, c.c_name, us.category_name, us.channel
ORDER BY total_revenue DESC
LIMIT 20
