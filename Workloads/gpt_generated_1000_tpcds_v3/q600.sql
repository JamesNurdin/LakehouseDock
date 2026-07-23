SELECT
    i.i_category AS item_category,
    i.i_class AS item_class,
    sm.sm_type AS ship_type,
    sm.sm_carrier AS ship_carrier,
    cp.cp_catalog_number AS catalog_number,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    (SUM(cs.cs_net_paid) + SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) - SUM(sr.sr_return_amt)) AS net_revenue
FROM tpcds.catalog_sales cs
JOIN tpcds.time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN tpcds.customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN tpcds.customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN tpcds.customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN tpcds.household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN tpcds.store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN tpcds.store s_ss ON ss.ss_store_sk = s_ss.s_store_sk
JOIN tpcds.promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN tpcds.customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN tpcds.customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN tpcds.household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN tpcds.time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN tpcds.store s_sr ON sr.sr_store_sk = s_sr.s_store_sk
JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN tpcds.customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN tpcds.customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN tpcds.household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN tpcds.ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN tpcds.warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN tpcds.promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN tpcds.customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN tpcds.customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN tpcds.customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN tpcds.customer_demographics cd_ws_ship ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
JOIN tpcds.household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN tpcds.household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
JOIN tpcds.warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
WHERE cp.cp_catalog_page_number IN (15, 17)
  AND ca_bill.ca_gmt_offset = -5.00
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_item_sk = i.i_item_sk
          AND ws2.ws_quantity > 0
          AND ws2.ws_net_paid > 0
    )
GROUP BY i.i_category, i.i_class, sm.sm_type, sm.sm_carrier, cp.cp_catalog_number
HAVING (SUM(cs.cs_net_paid) + SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) - SUM(sr.sr_return_amt)) > 10000
ORDER BY net_revenue DESC
LIMIT 100
