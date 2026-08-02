WITH filtered AS (
  SELECT
    w.w_warehouse_name,
    td.t_hour,
    cs.cs_net_profit,
    ws.ws_net_profit
  FROM catalog_sales cs
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
  JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
  JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
  WHERE td.t_hour BETWEEN 9 AND 17
    AND cc.cc_state = 'CA'
    AND w.w_state = 'TX'
    AND sm.sm_type = 'AIR'
    AND inv.inv_quantity_on_hand > 100
    AND wr.wr_return_tax > 10
    AND cs.cs_warehouse_sk IN (
      SELECT w_warehouse_sk FROM warehouse WHERE w_city = 'Liberty'
    )
)
SELECT
  w_warehouse_name,
  t_hour,
  SUM(cs_net_profit) AS catalog_profit,
  SUM(ws_net_profit) AS web_profit,
  SUM(cs_net_profit + ws_net_profit) AS total_profit,
  ROW_NUMBER() OVER (ORDER BY SUM(cs_net_profit + ws_net_profit) DESC) AS profit_rank
FROM filtered
GROUP BY w_warehouse_name, t_hour
ORDER BY total_profit DESC
LIMIT 5
