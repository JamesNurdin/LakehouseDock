WITH combined_sales AS (
    SELECT
        c.c_customer_id AS customer_id,
        c.c_name AS customer_name,
        i.i_category AS item_category,
        ss.ss_quantity * i.i_price AS revenue,
        ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category,
        ws.ws_quantity * i.i_price,
        ws.ws_quantity
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    customer_id,
    customer_name,
    item_category,
    SUM(revenue) AS total_revenue,
    SUM(quantity) AS total_quantity
FROM combined_sales
GROUP BY customer_id, customer_name, item_category
ORDER BY total_revenue DESC
LIMIT 10
