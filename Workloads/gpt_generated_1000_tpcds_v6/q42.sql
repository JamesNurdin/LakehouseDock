WITH agg AS (
  SELECT
    w.w_warehouse_sk,
    w.w_warehouse_name,
    sm.sm_code,
    td.t_shift,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS order_cnt
  FROM web_sales ws
  JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE td.t_shift = 'first'
    AND td.t_minute BETWEEN 0 AND 10
    AND w.w_state = 'CA'
    AND sm.sm_code = 'AIR'
  GROUP BY
    w.w_warehouse_sk,
    w.w_warehouse_name,
    sm.sm_code,
    td.t_shift
)
SELECT
  a.w_warehouse_name,
  a.sm_code,
  a.t_shift,
  a.total_profit,
  a.order_cnt,
  (SELECT AVG(ws2.ws_net_profit)
     FROM web_sales ws2
    WHERE ws2.ws_warehouse_sk = a.w_warehouse_sk) AS avg_warehouse_profit,
  RANK() OVER (PARTITION BY a.w_warehouse_name ORDER BY a.total_profit DESC) AS profit_rank
FROM agg a
ORDER BY a.total_profit DESC
LIMIT 100
