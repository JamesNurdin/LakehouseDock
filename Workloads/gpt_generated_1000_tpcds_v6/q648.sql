WITH
  store_profit AS (
    SELECT
      c.c_customer_id AS customer_id,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
      SUM(ss.ss_net_profit) AS total_net_profit,
      CASE WHEN SUM(ss.ss_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
      'Store' AS channel
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
  ),
  web_profit AS (
    SELECT
      c.c_customer_id AS customer_id,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
      SUM(ws.ws_net_profit) AS total_net_profit,
      CASE WHEN SUM(ws.ws_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
      'Web' AS channel
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE sm.sm_type = 'AIR'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
  )
SELECT DISTINCT
  customer_id,
  customer_name,
  total_net_profit,
  profit_category,
  channel
FROM (
  SELECT * FROM store_profit
  UNION ALL
  SELECT * FROM web_profit
) combined
ORDER BY total_net_profit DESC
LIMIT 100
