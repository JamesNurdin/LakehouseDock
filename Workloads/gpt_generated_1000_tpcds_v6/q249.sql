WITH qualified_customers AS (
    SELECT
        c.c_customer_sk,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address
    FROM tpcds.customer c
    WHERE regexp_like(c.c_email_address, '^.+@example\\.com$')
      AND substr(c.c_first_name, 1, 1) = substr(c.c_last_name, 1, 1)
)
SELECT
    w.w_city,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_profit) AS total_profit
FROM tpcds.web_sales ws
JOIN qualified_customers qc
    ON ws.ws_bill_customer_sk = qc.c_customer_sk
JOIN tpcds.warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
WHERE w.w_city LIKE 'S%'
  AND td.t_hour BETWEEN 9 AND 17
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_bill_customer_sk = qc.c_customer_sk
          AND ws2.ws_net_profit > 1000
        LIMIT 1
  )
GROUP BY w.w_city
ORDER BY total_profit DESC
LIMIT 10
