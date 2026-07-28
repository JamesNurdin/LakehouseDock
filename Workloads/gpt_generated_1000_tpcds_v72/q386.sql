SELECT
  t.t_hour,
  cc.cc_call_center_id,
  cd_ss.cd_gender,
  COUNT(DISTINCT ws.ws_order_number) AS web_orders,
  SUM(ws.ws_net_profit) AS total_web_profit,
  SUM(ss.ss_net_profit) AS total_store_profit,
  SUM(cr.cr_net_loss)   AS total_catalog_loss,
  SUM(sr.sr_net_loss)   AS total_store_return_loss,
  AVG(ws.ws_ext_tax)    AS avg_web_tax,
  MAX(ws.ws_ext_ship_cost) AS max_ship_cost
FROM time_dim t
JOIN store_sales ss
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd_ss
  ON cd_ss.cd_demo_sk = ss.ss_cdemo_sk
JOIN store_returns sr
  ON sr.sr_return_time_sk = t.t_time_sk
  AND sr.sr_item_sk = ss.ss_item_sk
  AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN customer_demographics cd_sr
  ON cd_sr.cd_demo_sk = sr.sr_cdemo_sk
JOIN catalog_returns cr
  ON cr.cr_returned_time_sk = t.t_time_sk
JOIN call_center cc
  ON cc.cc_call_center_sk = cr.cr_call_center_sk
JOIN customer_demographics cd_cr_ref
  ON cd_cr_ref.cd_demo_sk = cr.cr_refunded_cdemo_sk
JOIN customer_demographics cd_cr_ret
  ON cd_cr_ret.cd_demo_sk = cr.cr_returning_cdemo_sk
JOIN web_sales ws
  ON ws.ws_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd_ws_bill
  ON cd_ws_bill.cd_demo_sk = ws.ws_bill_cdemo_sk
JOIN customer_demographics cd_ws_ship
  ON cd_ws_ship.cd_demo_sk = ws.ws_ship_cdemo_sk
JOIN web_page wp
  ON wp.wp_web_page_sk = ws.ws_web_page_sk
WHERE cc.cc_state = 'CA'
  AND cc.cc_gmt_offset BETWEEN -8.00 AND -5.00
  AND cd_ss.cd_gender = 'F'
  AND wp.wp_type = 'content'
  AND ws.ws_ext_tax > 20.00
  AND ws.ws_ext_ship_cost < 1500.00
GROUP BY t.t_hour, cc.cc_call_center_id, cd_ss.cd_gender
ORDER BY total_web_profit DESC
LIMIT 100
