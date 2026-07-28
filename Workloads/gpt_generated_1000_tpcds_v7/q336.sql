SELECT
  cp.cp_department,
  i.i_item_id,
  cs.cs_order_number,
  cs.cs_net_profit,
  sm.sm_type,
  p.p_promo_name,
  RANK() OVER (PARTITION BY cp.cp_department ORDER BY cs.cs_net_profit DESC) AS profit_rank,
  SUM(cr.cr_return_amount) OVER (PARTITION BY cs.cs_order_number) AS total_return_amount,
  CASE WHEN cr.cr_return_quantity > 0 THEN 'Returned' ELSE 'No Return' END AS return_flag,
  s.s_store_name,
  t.t_hour
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
WHERE sm.sm_type = 'OVERNIGHT'
  AND p.p_channel_tv = 'N'
  AND ca.ca_state = 'CA'
