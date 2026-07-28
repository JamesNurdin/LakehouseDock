WITH agg AS (
  SELECT
    td.t_hour,
    ws.ws_ship_mode_sk,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(*) AS order_cnt
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  WHERE
    td.t_hour BETWEEN 8 AND 20
    AND td.t_am_pm IN ('AM', 'PM')
    AND ws.ws_ext_wholesale_cost > 1000
    AND ws.ws_quantity >= 1
    AND ws.ws_ship_date_sk BETWEEN 2452000 AND 2453000
    AND ws.ws_net_profit > 0
  GROUP BY ROLLUP (td.t_hour, ws.ws_ship_mode_sk)
  HAVING SUM(ws.ws_net_profit) > 10000
)
SELECT
  t_hour,
  ws_ship_mode_sk,
  total_profit,
  total_sales,
  order_cnt,
  CASE WHEN total_profit > 50000 THEN 'High' ELSE 'Low' END AS profit_category,
  RANK() OVER (PARTITION BY t_hour ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY t_hour, profit_rank
LIMIT 100
