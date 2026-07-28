SELECT
  d_store.d_year AS year,
  p_store.p_channel_email AS email_channel,
  SUM(ss.ss_net_profit) AS total_store_profit,
  SUM(cs.cs_net_profit) AS total_catalog_profit,
  SUM(cr.cr_net_loss) AS total_catalog_return_loss,
  SUM(sr.sr_net_loss) AS total_store_return_loss,
  SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
FROM store_sales ss
JOIN date_dim d_store
  ON ss.ss_sold_date_sk = d_store.d_date_sk
JOIN customer_demographics cd_cust
  ON ss.ss_cdemo_sk = cd_cust.cd_demo_sk
JOIN customer_address ca_cust
  ON ss.ss_addr_sk = ca_cust.ca_address_sk
JOIN promotion p_store
  ON ss.ss_promo_sk = p_store.p_promo_sk
LEFT JOIN web_site ws
  ON d_store.d_date_sk = ws.web_open_date_sk
LEFT JOIN web_page wp
  ON d_store.d_date_sk = wp.wp_creation_date_sk
JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN catalog_sales cs
  ON ss.ss_sold_date_sk = cs.cs_sold_date_sk
JOIN date_dim d_cat
  ON cs.cs_sold_date_sk = d_cat.d_date_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p_cat
  ON cs.cs_promo_sk = p_cat.p_promo_sk
JOIN customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN catalog_returns cr
  ON cs.cs_order_number = cr.cr_order_number
LEFT JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN inventory inv
  ON w.w_warehouse_sk = inv.inv_warehouse_sk
 AND d_store.d_date_sk = inv.inv_date_sk
GROUP BY
  d_store.d_year,
  p_store.p_channel_email
ORDER BY
  d_store.d_year DESC,
  p_store.p_channel_email
LIMIT 100
