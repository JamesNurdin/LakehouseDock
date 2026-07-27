SELECT
    cd.cd_gender AS gender,
    hd.hd_income_band_sk AS income_band_sk,
    sm.sm_type AS ship_mode_type,
    cp.cp_department AS department,
    w_ship.w_state AS warehouse_state,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)) AS total_net_profit
FROM catalog_sales cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w_ship ON cs.cs_warehouse_sk = w_ship.w_warehouse_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN inventory inv ON inv.inv_warehouse_sk = w_ship.w_warehouse_sk
JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
WHERE cp.cp_department = 'Electronics'
  AND sm.sm_type = 'AIR'
GROUP BY
    cd.cd_gender,
    hd.hd_income_band_sk,
    sm.sm_type,
    cp.cp_department,
    w_ship.w_state
ORDER BY total_net_profit DESC
LIMIT 100
