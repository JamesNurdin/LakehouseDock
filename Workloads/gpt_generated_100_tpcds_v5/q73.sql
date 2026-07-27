WITH time_filtered AS (
    SELECT
        t_time_sk,
        t_hour,
        t_minute,
        t_meal_time,
        CONCAT(CAST(t_hour AS VARCHAR), ':', lpad(CAST(t_minute AS VARCHAR), 2, '0')) AS time_label
    FROM time_dim
    WHERE regexp_like(t_meal_time, '^b.*')
      AND t_meal_time LIKE '%fast%'
)
SELECT
    tf.time_label,
    tf.t_meal_time,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_tickets,
    SUM(sr.sr_return_amt_inc_tax) AS total_returns,
    (SUM(ws.ws_ext_sales_price) - SUM(sr.sr_return_amt_inc_tax)) AS net_sales
FROM time_filtered tf
LEFT JOIN web_sales ws
    ON ws.ws_sold_time_sk = tf.t_time_sk
LEFT JOIN store_returns sr
    ON sr.sr_return_time_sk = tf.t_time_sk
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws2
    WHERE ws2.ws_sold_time_sk = tf.t_time_sk
      AND ws2.ws_ship_mode_sk IN (15, 20)
)
GROUP BY tf.time_label, tf.t_meal_time
HAVING SUM(ws.ws_ext_sales_price) > (
    SELECT AVG(sr2.sr_return_amt_inc_tax)
    FROM store_returns sr2
)
ORDER BY net_sales DESC
LIMIT 100
