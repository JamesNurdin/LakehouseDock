WITH
  bill_sales AS (
    SELECT
      ws.ws_bill_customer_sk AS cust_sk,
      ws.ws_ship_mode_sk AS ship_mode_sk,
      SUM(ws.ws_net_paid) AS total_paid,
      COUNT(*) AS order_cnt
    FROM tpcds.web_sales ws
    WHERE ws.ws_ext_list_price > 2000
      AND ws.ws_ship_mode_sk IN (
        SELECT sm.sm_ship_mode_sk
        FROM tpcds.ship_mode sm
        WHERE sm.sm_carrier = 'MSC'
      )
    GROUP BY ws.ws_bill_customer_sk, ws.ws_ship_mode_sk
  ),
  ship_sales AS (
    SELECT
      ws.ws_ship_customer_sk AS cust_sk,
      ws.ws_ship_mode_sk AS ship_mode_sk,
      SUM(ws.ws_net_profit) AS total_profit,
      AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM tpcds.web_sales ws
    WHERE ws.ws_ext_discount_amt > 0
      AND ws.ws_ship_mode_sk IN (
        SELECT sm.sm_ship_mode_sk
        FROM tpcds.ship_mode sm
        WHERE sm.sm_carrier = 'MSC'
      )
    GROUP BY ws.ws_ship_customer_sk, ws.ws_ship_mode_sk
  ),
  common_customers AS (
    SELECT cust_sk FROM bill_sales
    INTERSECT
    SELECT cust_sk FROM ship_sales
  ),
  computed_set AS (
    SELECT 1 AS dummy UNION ALL SELECT 2 UNION ALL SELECT 3
  )
SELECT
  c.c_customer_id,
  sm.sm_ship_mode_id,
  td.t_hour,
  SUM(ws.ws_ext_sales_price) AS sum_sales,
  AVG(ws.ws_net_profit) AS avg_profit,
  MIN(ws.ws_ext_discount_amt) AS min_discount,
  MAX(ws.ws_ext_discount_amt) AS max_discount,
  COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
  (SELECT AVG(ws2.ws_net_profit) FROM tpcds.web_sales ws2) AS overall_avg_profit
FROM tpcds.web_sales ws
JOIN tpcds.customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN tpcds.ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.time_dim td
  ON ws.ws_sold_time_sk = td.t_time_sk
CROSS JOIN (SELECT dummy FROM computed_set) cs
WHERE sm.sm_carrier = 'MSC'
  AND sm.sm_contract = 'Ek'
  AND td.t_am_pm = 'PM'
  AND td.t_second BETWEEN 5 AND 15
  AND ws.ws_ext_list_price > 2000
  AND ws.ws_bill_customer_sk NOT IN (
    SELECT ws2.ws_bill_customer_sk
    FROM tpcds.web_sales ws2
    WHERE ws2.ws_net_profit < 0
  )
  AND ws.ws_bill_customer_sk IN (SELECT cust_sk FROM common_customers)
GROUP BY c.c_customer_id, sm.sm_ship_mode_id, td.t_hour
ORDER BY sum_sales DESC
LIMIT 100
