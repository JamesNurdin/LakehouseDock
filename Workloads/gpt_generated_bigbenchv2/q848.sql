WITH combined_sales AS (
    SELECT ss.ss_transaction_id AS transaction_id,
           ss.ss_customer_id AS customer_id,
           ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           ss.ss_ts AS ts,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_transaction_id AS transaction_id,
           ws.ws_customer_id AS customer_id,
           ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           ws.ws_ts AS ts,
           'web' AS channel
    FROM web_sales ws
)
SELECT i.i_category AS category,
       cs.channel,
       SUM(cs.quantity) AS total_quantity,
       SUM(cs.quantity * i.i_price) AS total_revenue
FROM combined_sales cs
JOIN items i ON cs.item_id = i.i_item_id
GROUP BY i.i_category, cs.channel
ORDER BY total_revenue DESC
