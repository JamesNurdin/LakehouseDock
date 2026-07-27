SELECT
  cp.cp_catalog_number AS catalog_number,
  sm_sales.sm_type AS ship_mode_type,
  r_cr.r_reason_desc AS return_reason,
  w_sales.w_state AS warehouse_state,
  SUM(cs.cs_net_profit) AS total_catalog_sales_profit,
  SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
  SUM(ws.ws_net_profit) AS total_web_sales_profit,
  SUM(sr.sr_net_loss) AS total_store_returns_loss,
  SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i_sales
  ON cs.cs_item_sk = i_sales.i_item_sk
JOIN ship_mode sm_sales
  ON cs.cs_ship_mode_sk = sm_sales.sm_ship_mode_sk
JOIN warehouse w_sales
  ON cs.cs_warehouse_sk = w_sales.w_warehouse_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_ship
  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN item i_ret
  ON cr.cr_item_sk = i_ret.i_item_sk
JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN ship_mode sm_cr
  ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN warehouse w_cr
  ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN catalog_page cp_cr
  ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
JOIN customer_demographics cd_refunded
  ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_address ca_refunded
  ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_demographics cd_returning
  ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN customer_address ca_returning
  ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i_sales.i_item_sk
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN customer_demographics cd_sr
  ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN customer_address ca_sr
  ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i_sales.i_item_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm_ws
  ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws
  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN customer_demographics cd_ws_bill
  ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN customer_address ca_ws_bill
  ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_demographics cd_ws_ship
  ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
JOIN customer_address ca_ws_ship
  ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN inventory inv
  ON inv.inv_item_sk = i_sales.i_item_sk
 AND inv.inv_warehouse_sk = w_sales.w_warehouse_sk
GROUP BY
  cp.cp_catalog_number,
  sm_sales.sm_type,
  r_cr.r_reason_desc,
  w_sales.w_state
ORDER BY total_catalog_sales_profit DESC
LIMIT 100
