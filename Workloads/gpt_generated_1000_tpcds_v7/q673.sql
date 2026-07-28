SELECT
  i.i_category,
  cp.cp_department,
  w.w_state,
  sm.sm_type,
  r.r_reason_desc,
  COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
  SUM(cs.cs_net_paid) AS total_catalog_sales,
  SUM(ss.ss_net_paid) AS total_store_sales,
  SUM(ws.ws_net_paid) AS total_web_sales,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(p.p_cost) AS avg_promo_cost,
  MIN(i.i_current_price) AS min_item_price,
  MAX(i.i_current_price) AS max_item_price
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN promotion p
  ON p.p_item_sk = i.i_item_sk
JOIN customer c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE cp.cp_type = 'PROMO'
  AND cr.cr_return_tax > 10.0
  AND wp.wp_autogen_flag = 'Y'
GROUP BY i.i_category, cp.cp_department, w.w_state, sm.sm_type, r.r_reason_desc
LIMIT 100
