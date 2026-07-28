SELECT
    cc.cc_name,
    sm.sm_type,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(sr.sr_net_loss)   AS store_return_loss,
    SUM(cr.cr_net_loss)   AS catalog_return_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
FROM store_sales ss
JOIN date_dim d_sales
  ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN reason r2
  ON cr.cr_reason_sk = r2.r_reason_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
  ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d_wp_creation.d_date_sk
JOIN inventory inv
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
  AND inv.inv_date_sk = d_sales.d_date_sk
WHERE d_sales.d_year = 2001
GROUP BY cc.cc_name, sm.sm_type
ORDER BY cc.cc_name, sm.sm_type
