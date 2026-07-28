SELECT
    s.s_store_name,
    w_cs.w_warehouse_name,
    sm_cs.sm_type,
    r_cat.r_reason_desc AS catalog_return_reason,
    r_store.r_reason_desc AS store_return_reason,
    SUM(cs.cs_net_profit)          AS total_catalog_profit,
    SUM(ss.ss_net_profit)          AS total_store_profit,
    SUM(ws.ws_net_profit)          AS total_web_profit,
    SUM(cr.cr_net_loss)            AS total_catalog_return_loss,
    SUM(sr.sr_net_loss)            AS total_store_return_loss
FROM
    catalog_sales cs
JOIN time_dim td_cs
      ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN item i_cat
      ON cs.cs_item_sk = i_cat.i_item_sk
JOIN household_demographics hd_cat_bill
      ON cs.cs_bill_hdemo_sk = hd_cat_bill.hd_demo_sk
JOIN household_demographics hd_cat_ship
      ON cs.cs_ship_hdemo_sk = hd_cat_ship.hd_demo_sk
JOIN customer_address ca_cat_bill
      ON cs.cs_bill_addr_sk = ca_cat_bill.ca_address_sk
JOIN customer_address ca_cat_ship
      ON cs.cs_ship_addr_sk = ca_cat_ship.ca_address_sk
JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cs
      ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN warehouse w_cs
      ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk

-- catalog returns linked to the same order
JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
JOIN time_dim td_cr
      ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN reason r_cat
      ON cr.cr_reason_sk = r_cat.r_reason_sk

-- inventory for the same item/warehouse
JOIN inventory inv
      ON inv.inv_item_sk = i_cat.i_item_sk
     AND inv.inv_warehouse_sk = w_cs.w_warehouse_sk

-- store sales (bridge through the shared item dimension)
JOIN store_sales ss
      ON ss.ss_item_sk = i_cat.i_item_sk
JOIN time_dim td_ss
      ON ss.ss_sold_time_sk = td_ss.t_time_sk
JOIN household_demographics hd_ss
      ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss
      ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN store s
      ON ss.ss_store_sk = s.s_store_sk

-- store returns linked to the same ticket
JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN time_dim td_sr
      ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN reason r_store
      ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN household_demographics hd_sr
      ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr
      ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN store s2
      ON sr.sr_store_sk = s2.s_store_sk   -- second alias of STORE

-- web sales (again via the shared item dimension)
JOIN web_sales ws
      ON ws.ws_item_sk = i_cat.i_item_sk
JOIN time_dim td_ws
      ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN household_demographics hd_ws
      ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
JOIN customer_address ca_ws
      ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
JOIN ship_mode sm_ws
      ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws
      ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk

GROUP BY
    s.s_store_name,
    w_cs.w_warehouse_name,
    sm_cs.sm_type,
    r_cat.r_reason_desc,
    r_store.r_reason_desc
ORDER BY total_catalog_profit DESC
LIMIT 100
