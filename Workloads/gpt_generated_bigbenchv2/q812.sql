WITH combined_sales AS (
    -- Physical store sales
    SELECT
        ss.ss_store_id,
        s.s_store_name AS store_name,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue,
        c.c_customer_id AS customer_id
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    WHERE i.i_price > 20
    UNION ALL
    -- Online (web) sales – assign a pseudo store name
    SELECT
        NULL AS ss_store_id,
        CAST('Online' AS varchar) AS store_name,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue,
        c.c_customer_id AS customer_id
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    WHERE i.i_price > 20
)
SELECT
    store_name,
    i_category_name,
    SUM(quantity) AS total_quantity,
    SUM(revenue) AS total_revenue,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM combined_sales
GROUP BY
    store_name,
    i_category_name
ORDER BY total_revenue DESC
LIMIT 20
