WITH sales_all AS (
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
    c.c_customer_id,
    c.c_name,
    i.i_category_id,
    i.i_category_name,
    SUM(s.quantity) AS total_quantity,
    SUM(s.quantity * i.i_price) AS total_revenue,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    COUNT(DISTINCT s.channel) AS sales_channels
FROM sales_all s
JOIN customers c
    ON s.customer_id = c.c_customer_id
JOIN items i
    ON s.item_id = i.i_item_id
GROUP BY
    c.c_customer_id,
    c.c_name,
    i.i_category_id,
    i.i_category_name
HAVING SUM(s.quantity * i.i_price) > 5000
ORDER BY total_revenue DESC
LIMIT 20
