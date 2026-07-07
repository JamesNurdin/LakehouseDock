WITH unified_sales AS (
    SELECT ss_transaction_id AS transaction_id,
           ss_customer_id AS customer_id,
           ss_item_id AS item_id,
           ss_quantity AS quantity,
           ss_ts AS ts,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_transaction_id AS transaction_id,
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
    i.i_category,
    SUM(us.quantity) AS total_quantity,
    SUM(us.quantity * i.i_price) AS total_revenue,
    COUNT(DISTINCT us.transaction_id) AS distinct_transactions
FROM unified_sales us
JOIN customers c
    ON us.customer_id = c.c_customer_id
JOIN items i
    ON us.item_id = i.i_item_id
GROUP BY
    c.c_customer_id,
    c.c_name,
    i.i_category_id,
    i.i_category
ORDER BY total_revenue DESC
LIMIT 10
