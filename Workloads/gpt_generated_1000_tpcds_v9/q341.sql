SELECT d_sold.d_year,
       p.p_promo_name,
       w.w_state,
       SUM(ws.ws_net_profit) AS total_web_profit,
       SUM(sr.sr_net_loss) AS total_store_return_loss,
       SUM(cr.cr_net_loss) AS total_catalog_return_loss,
       COUNT(DISTINCT ws.ws_order_number) AS distinct_order_count,
       COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_return_count,
       COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_return_count,
       AVG(p.p_cost) AS avg_promo_cost,
       AVG(ws.ws_ext_discount_amt) AS avg_web_discount
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d_sold.d_date_sk
JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sold.d_date_sk
JOIN customer c_cr_refunded ON cr.cr_refunded_customer_sk = c_cr_refunded.c_customer_sk
JOIN customer_demographics cd_cr_refunded ON cr.cr_refunded_cdemo_sk = cd_cr_refunded.cd_demo_sk
JOIN household_demographics hd_cr_refunded ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
JOIN customer c_cr_returning ON cr.cr_returning_customer_sk = c_cr_returning.c_customer_sk
JOIN customer_demographics cd_cr_returning ON cr.cr_returning_cdemo_sk = cd_cr_returning.cd_demo_sk
JOIN household_demographics hd_cr_returning ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
GROUP BY d_sold.d_year, p.p_promo_name, w.w_state
ORDER BY total_web_profit DESC
LIMIT 100
