SELECT
  i.i_category,
  i.i_brand,
  w.w_state,
  cc.cc_state AS call_center_state,
  SUM(cs.cs_net_paid) AS total_catalog_net_paid,
  SUM(ws.ws_net_paid) AS total_web_net_paid,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
  COUNT(DISTINCT ws.ws_order_number) AS web_orders,
  AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
  AVG(ws.ws_ext_discount_amt) AS avg_web_discount,
  MAX(p.p_cost) AS max_promo_cost
FROM catalog_sales cs
JOIN time_dim td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  AND wr.wr_item_sk = i.i_item_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
  AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
WHERE cc.cc_state = 'CA'
  AND i.i_category = 'Electronics'
  AND cd_bill.cd_gender = 'M'
  AND i.i_rec_start_date >= DATE '2001-01-01'
  AND EXISTS (SELECT 1 FROM inventory inv2 WHERE inv2.inv_item_sk = i.i_item_sk AND inv2.inv_quantity_on_hand > 0)
GROUP BY i.i_category, i.i_brand, w.w_state, cc.cc_state
ORDER BY total_catalog_net_paid DESC
LIMIT 100
