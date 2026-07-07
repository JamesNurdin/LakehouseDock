WITH store_revenue AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category,
        ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_revenue AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category,
        ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    c_customer_id,
    c_name,
    i_category,
    SUM(revenue) AS total_revenue
FROM (
    SELECT * FROM store_revenue
    UNION ALL
    SELECT * FROM web_revenue
) AS combined
GROUP BY c_customer_id, c_name, i_category
ORDER BY total_revenue DESC
LIMIT 100
