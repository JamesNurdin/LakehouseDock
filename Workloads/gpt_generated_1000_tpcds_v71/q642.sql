SELECT
  ca.ca_state,
  sm.sm_type,
  td.t_hour,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
  SUM(cs.cs_net_paid) AS catalog_net_paid,
  SUM(ss.ss_net_paid) AS store_net_paid,
  SUM(ws.ws_net_paid) AS web_net_paid,
  SUM(sr.sr_return_amt) AS store_return_amt,
  SUM(COALESCE(wr.wr_return_amt, 0)) AS web_return_amt,
  AVG(p.p_cost) AS avg_promo_cost,
  MIN(inv.inv_quantity_on_hand) AS min_inventory,
  MAX(inv.inv_quantity_on_hand) AS max_inventory
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN time_dim td
  ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN inventory inv
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss
  ON ss.ss_sold_time_sk = td.t_time_sk
  AND ss.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
  AND sr.sr_return_time_sk = td.t_time_sk
  AND sr.sr_addr_sk = ca.ca_address_sk
JOIN reason r_store
  ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN web_sales ws
  ON ws.ws_sold_time_sk = td.t_time_sk
  AND ws.ws_bill_addr_sk = ca.ca_address_sk
  AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  AND ws.ws_warehouse_sk = w.w_warehouse_sk
  AND ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
  AND wr.wr_returned_time_sk = td.t_time_sk
  AND wr.wr_refunded_addr_sk = ca.ca_address_sk
  AND wr.wr_returning_addr_sk = ca.ca_address_sk
  AND wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN reason r_web
  ON wr.wr_reason_sk = r_web.r_reason_sk
WHERE ca.ca_state = 'TX'
  AND cs.cs_quantity > 5
  AND td.t_hour BETWEEN 9 AND 17
  AND p.p_discount_active = 'Y'
  AND inv.inv_quantity_on_hand > 0
GROUP BY ca.ca_state, sm.sm_type, td.t_hour
ORDER BY ca.ca_state, sm.sm_type, td.t_hour
LIMIT 100
