WITH ws_agg AS (
  SELECT
    w.w_warehouse_name,
    ca.ca_state,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_count
  FROM web_sales ws
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  GROUP BY w.w_warehouse_name, ca.ca_state
)
SELECT
  ws_agg.w_warehouse_name,
  ws_agg.ca_state,
  ws_agg.total_net_profit,
  ws_agg.avg_vehicle_count,
  RANK() OVER (PARTITION BY ws_agg.w_warehouse_name ORDER BY ws_agg.total_net_profit DESC) AS state_profit_rank,
  CASE WHEN ws_agg.total_net_profit > 50000 THEN 'High Profit' ELSE 'Moderate Profit' END AS profit_category
FROM ws_agg
ORDER BY ws_agg.w_warehouse_name, state_profit_rank
