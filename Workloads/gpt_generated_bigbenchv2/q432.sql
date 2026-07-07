WITH store_data AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        'store' AS channel,
        i.i_price AS price
    FROM store_sales ss
    INNER JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    INNER JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_data AS (
    SELECT
        ws.ws_customer_id AS customer_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        'web' AS channel,
        i.i_price AS price
    FROM web_sales ws
    INNER JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    INNER JOIN items i ON ws.ws_item_id = i.i_item_id
),
all_sales AS (
    SELECT
        customer_id,
        item_id,
        quantity,
        channel,
        price
    FROM store_data
    UNION ALL
    SELECT
        customer_id,
        item_id,
        quantity,
        channel,
        price
    FROM web_data
)
SELECT
    c.c_name AS customer_name,
    i.i_category AS item_category,
    s.channel,
    SUM(s.quantity) AS total_quantity,
    SUM(s.quantity * s.price) AS total_revenue
FROM all_sales s
INNER JOIN customers c ON s.customer_id = c.c_customer_id
INNER JOIN items i ON s.item_id = i.i_item_id
GROUP BY
    c.c_name,
    i.i_category,
    s.channel
ORDER BY
    total_revenue DESC
LIMIT 100
