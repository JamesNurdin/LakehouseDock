SELECT
    d.d_year,
    s.s_store_name,
    p.p_promo_name,
    hd.hd_buy_potential,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(sr.sr_net_loss) AS total_store_returns_loss,
    SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_qty,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    CASE WHEN SUM(ss.ss_net_paid) > 50000 THEN 'High' ELSE 'Low' END AS sales_category
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    AND cs.cs_sold_time_sk = t.t_time_sk
    AND cs.cs_call_center_sk = cc.cc_call_center_sk
    AND cs.cs_promo_sk = p.p_promo_sk
    AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    AND cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    AND cs.cs_ship_date_sk = d.d_date_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_returned_time_sk = t.t_time_sk
    AND cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    AND cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    AND cr.cr_call_center_sk = cc.cc_call_center_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_return_time_sk = t.t_time_sk
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_hdemo_sk = hd.hd_demo_sk
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_sold_time_sk = t.t_time_sk
    AND ws.ws_ship_date_sk = d.d_date_sk
    AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    AND ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    AND ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    AND wp.wp_creation_date_sk = d.d_date_sk
    AND wp.wp_access_date_sk = d.d_date_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    AND we.web_open_date_sk = d.d_date_sk
    AND we.web_close_date_sk = d.d_date_sk
WHERE p.p_channel_press = 'N'
  AND s.s_street_type = 'Street'
  AND cs.cs_warehouse_sk = 12
  AND d.d_year = 2001
GROUP BY d.d_year, s.s_store_name, p.p_promo_name, hd.hd_buy_potential
ORDER BY total_store_sales DESC
LIMIT 100
