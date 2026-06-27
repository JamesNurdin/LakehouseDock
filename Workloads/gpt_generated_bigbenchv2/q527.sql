WITH combined_sales AS (
    -- Store sales (physical stores)
    SELECT
        s.s_store_name AS store_name,
        c.c_customer_id,
        c.c_name AS customer_name,
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id

    UNION ALL

    -- Web sales (online)
    SELECT
        'Online' AS store_name,
        c.c_customer_id,
        c.c_name AS customer_name,
        i.i_category_id,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
aggregated AS (
    SELECT
        store_name,
        i_category_name,
        c_customer_id,
        customer_name,
        SUM(quantity) AS total_quantity,
        SUM(revenue) AS total_revenue
    FROM combined_sales
    GROUP BY
        store_name,
        i_category_name,
        c_customer_id,
        customer_name
),
ranked AS (
    SELECT
        store_name,
        i_category_name,
        c_customer_id,
        customer_name,
        total_quantity,
        total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY store_name, i_category_name
            ORDER BY total_revenue DESC
        ) AS rn
    FROM aggregated
)
SELECT
    store_name,
    i_category_name,
    c_customer_id,
    customer_name,
    total_quantity,
    total_revenue
FROM ranked
WHERE rn <= 5
ORDER BY
    store_name,
    i_category_name,
    total_revenue DESC
