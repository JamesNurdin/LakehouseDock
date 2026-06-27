WITH all_sales AS (
    SELECT
        ss_customer_id AS customer_id,
        ss_item_id    AS item_id,
        ss_quantity   AS quantity,
        'store'       AS channel
    FROM store_sales
    UNION ALL
    SELECT
        ws_customer_id AS customer_id,
        ws_item_id    AS item_id,
        ws_quantity   AS quantity,
        'web'         AS channel
    FROM web_sales
)
SELECT
    c.c_customer_id,
    c.c_name,
    i.i_category_name,
    SUM(a.quantity)                     AS total_quantity,
    SUM(a.quantity * i.i_price)          AS total_spent,
    COUNT(DISTINCT a.channel)            AS distinct_channels
FROM all_sales a
JOIN customers c ON a.customer_id = c.c_customer_id
JOIN items     i ON a.item_id    = i.i_item_id
GROUP BY
    c.c_customer_id,
    c.c_name,
    i.i_category_name
ORDER BY total_spent DESC
LIMIT 50
