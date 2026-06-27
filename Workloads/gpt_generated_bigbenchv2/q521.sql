WITH all_sales AS (
    SELECT
        ss_transaction_id AS transaction_id,
        ss_customer_id AS customer_id,
        ss_item_id AS item_id,
        ss_quantity AS quantity,
        ss_ts AS ts,
        'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT
        ws_transaction_id AS transaction_id,
        ws_customer_id AS customer_id,
        ws_item_id AS item_id,
        ws_quantity AS quantity,
        ws_ts AS ts,
        'web' AS channel
    FROM web_sales
)
SELECT
    c.c_name AS customer_name,
    i.i_category_name AS category_name,
    s.channel,
    SUM(s.quantity) AS total_quantity,
    SUM(s.quantity * i.i_price) AS total_revenue
FROM all_sales s
JOIN customers c
    ON c.c_customer_id = s.customer_id
JOIN items i
    ON i.i_item_id = s.item_id
GROUP BY c.c_name, i.i_category_name, s.channel
ORDER BY total_revenue DESC
LIMIT 100
