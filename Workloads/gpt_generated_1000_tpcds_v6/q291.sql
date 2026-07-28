/*
Goal: Analyze overall profitability by call center, shipping mode and item color across catalog and web sales, including returns, while exercising deep joins across all selected TPC‑DS tables and re‑using dimension tables (customer, household_demographics, ship_mode) under different aliases.
*/
SELECT
    cc.cc_name,
    sm.sm_type,
    i.i_color,
    COUNT(DISTINCT cs.cs_order_number)            AS num_orders,
    SUM(cs.cs_net_profit)                         AS catalog_net_profit,
    SUM(ws.ws_net_profit)                         AS web_net_profit,
    SUM(cr.cr_net_loss)                           AS total_return_loss
FROM catalog_sales cs
JOIN customer c_bill
     ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
     ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN household_demographics hd_bill
     ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
     ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm               -- ship mode for catalog sales
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_returns cr
     ON cr.cr_order_number = cs.cs_order_number
JOIN web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsit
     ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN ship_mode sm_ws            -- ship mode for web sales (different alias)
     ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
GROUP BY ROLLUP (cc.cc_name, sm.sm_type, i.i_color)
ORDER BY catalog_net_profit DESC
LIMIT 100
