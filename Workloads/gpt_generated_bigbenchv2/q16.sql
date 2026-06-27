WITH store_sales_joined AS (
    SELECT
        ss.ss_customer_id AS c_customer_id,
        c.c_name,
        ss.ss_store_id AS s_store_id,
        s.s_store_name,
        ss.ss_item_id AS i_item_id,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        i.i_price
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_joined AS (
    SELECT
        ws.ws_customer_id AS c_customer_id,
        c.c_name,
        NULL AS s_store_id,
        NULL AS s_store_name,
        ws.ws_item_id AS i_item_id,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        i.i_price
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    c_customer_id,
    c_name,
    i_category_name,
    COALESCE(s_store_name, 'Online') AS sales_channel,
    SUM(quantity) AS total_quantity,
    SUM(quantity * i_price) AS total_revenue
FROM (
    SELECT c_customer_id, c_name, i_category_name, s_store_name, quantity, i_price
    FROM store_sales_joined
    UNION ALL
    SELECT c_customer_id, c_name, i_category_name, s_store_name, quantity, i_price
    FROM web_sales_joined
) AS combined
GROUP BY c_customer_id, c_name, i_category_name, COALESCE(s_store_name, 'Online')
ORDER BY total_revenue DESC
LIMIT 50
