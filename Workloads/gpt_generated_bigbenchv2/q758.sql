WITH combined_sales AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        i.i_price AS price,
        'store' AS channel
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        ws.ws_customer_id AS customer_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        i.i_price AS price,
        'web' AS channel
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    c.c_customer_id,
    c.c_name,
    cs.channel,
    SUM(cs.quantity) AS total_quantity,
    SUM(cs.quantity * cs.price) AS total_revenue,
    COUNT(DISTINCT cs.item_id) AS distinct_items_purchased
FROM combined_sales cs
JOIN customers c ON cs.customer_id = c.c_customer_id
GROUP BY c.c_customer_id, c.c_name, cs.channel
ORDER BY total_revenue DESC
LIMIT 20
