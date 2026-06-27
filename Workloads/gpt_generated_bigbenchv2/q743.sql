WITH store_sales_data AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_sales_data AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
all_sales AS (
    SELECT * FROM store_sales_data
    UNION ALL
    SELECT * FROM web_sales_data
)
SELECT
    c_customer_id,
    c_name,
    i_category_name,
    sum(quantity) AS total_quantity,
    sum(revenue) AS total_revenue,
    sum(revenue) / nullif(sum(quantity), 0) AS avg_price_per_item
FROM all_sales
GROUP BY
    c_customer_id,
    c_name,
    i_category_name
ORDER BY total_revenue DESC
LIMIT 100
