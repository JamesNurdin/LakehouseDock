SELECT
    w.w_state,
    i.i_category,
    hd.hd_buy_potential,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    SUM(cs.cs_net_paid) AS catalog_net_paid,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(ws.ws_net_paid) AS web_net_paid,
    SUM(ws.ws_net_profit) AS web_net_profit
FROM
    time_dim t
    JOIN catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
WHERE
    t.t_hour = 14
    AND i.i_brand = 'Brand#23'
    AND w.w_state = 'CA'
    AND hd.hd_income_band_sk = 13
    AND p.p_discount_active = 'Y'
    AND cs.cs_quantity > 5
GROUP BY ROLLUP (w.w_state, i.i_category, hd.hd_buy_potential)
LIMIT 100
