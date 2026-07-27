SELECT
  s.s_state AS store_state,
  i_main.i_brand AS item_brand,
  cc.cc_name AS call_center_name,
  sm_main.sm_type AS ship_mode_type,
  SUM(cs.cs_net_profit) AS total_catalog_profit,
  SUM(sr.sr_net_loss) AS total_store_return_loss,
  SUM(wr.wr_net_loss) AS total_web_return_loss,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  AVG(ws.ws_net_paid_inc_ship) AS avg_web_net_paid_inc_ship
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i_main
  ON cs.cs_item_sk = i_main.i_item_sk
JOIN time_dim td_cs
  ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
  ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN ship_mode sm_main
  ON cs.cs_ship_mode_sk = sm_main.sm_ship_mode_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i_main.i_item_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN time_dim td_sr
  ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN customer_demographics cd_sr
  ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr
  ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr
  ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i_main.i_item_sk
JOIN time_dim td_ws
  ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN customer_demographics cd_ws_bill
  ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN household_demographics hd_ws_bill
  ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN customer_address ca_ws_bill
  ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_demographics cd_ws_ship
  ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
JOIN household_demographics hd_ws_ship
  ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
JOIN customer_address ca_ws_ship
  ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN ship_mode sm_ws
  ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
JOIN time_dim td_wr
  ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN item i_wr
  ON wr.wr_item_sk = i_wr.i_item_sk
JOIN customer_demographics cd_wr_ref
  ON wr.wr_refunded_cdemo_sk = cd_wr_ref.cd_demo_sk
JOIN household_demographics hd_wr_ref
  ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
JOIN customer_address ca_wr_ref
  ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
JOIN customer_demographics cd_wr_ret
  ON wr.wr_returning_cdemo_sk = cd_wr_ret.cd_demo_sk
JOIN household_demographics hd_wr_ret
  ON wr.wr_returning_hdemo_sk = hd_wr_ret.hd_demo_sk
JOIN customer_address ca_wr_ret
  ON wr.wr_returning_addr_sk = ca_wr_ret.ca_address_sk
JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE i_main.i_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
GROUP BY
  s.s_state,
  i_main.i_brand,
  cc.cc_name,
  sm_main.sm_type
ORDER BY total_catalog_profit DESC
LIMIT 100
