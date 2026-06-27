WITH all_sales AS (
    SELECT ss_transaction_id AS transaction_id,
           ss_customer_id   AS customer_id,
           ss_item_id       AS item_id,
           ss_quantity      AS quantity,
           'store'          AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_transaction_id AS transaction_id,
           ws_customer_id   AS customer_id,
           ws_item_id       AS item_id,
           ws_quantity      AS quantity,
           'web'            AS channel
    FROM web_sales
)
SELECT c.c_customer_id,
       i.i_category_name,
       s.channel,
       SUM(s.quantity)                         AS total_quantity,
       SUM(s.quantity * i.i_price)             AS total_revenue,
       AVG(i.i_price)                          AS avg_item_price,
       COUNT(DISTINCT s.transaction_id)        AS distinct_transactions
FROM all_sales s
JOIN customers c ON s.customer_id = c.c_customer_id
JOIN items i     ON s.item_id    = i.i_item_id
GROUP BY c.c_customer_id, i.i_category_name, s.channel
ORDER BY total_revenue DESC
LIMIT 10
