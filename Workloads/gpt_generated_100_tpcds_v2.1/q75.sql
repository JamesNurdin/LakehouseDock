SELECT
    s.s_store_name,
    i.i_category,
    td_ss.t_hour,
    sm_cr.sm_carrier,
    r_sr.r_reason_desc,
    we.web_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_sales_orders,
    SUM(ss.ss_net_paid) AS total_store_sales_net_paid,
    SUM(ws.ws_net_paid) AS total_web_sales_net_paid,
    SUM(sr.sr_refunded_cash) AS total_store_returns_refunded_cash,
    SUM(cr.cr_refunded_cash) AS total_catalog_returns_refunded_cash,
    AVG(ss.ss_net_profit) AS avg_store_sales_net_profit,
    MIN(ss.ss_net_paid) AS min_store_sales_net_paid,
    MAX(ws.ws_net_paid) AS max_web_sales_net_paid
FROM store_sales ss
JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN customer_address ca_cr ON cr.cr_refunded_addr_sk = ca_cr.ca_address_sk
JOIN customer_demographics cd_cr ON cr.cr_refunded_cdemo_sk = cd_cr.cd_demo_sk
JOIN household_demographics hd_cr ON cr.cr_refunded_hdemo_sk = hd_cr.hd_demo_sk
JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN customer_demographics cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
JOIN customer_address ca_ws ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
WHERE
    i.i_current_price > 20.00
    AND i.i_category = 'Sports'
    AND s.s_state = 'CA'
    AND td_ss.t_hour BETWEEN 9 AND 17
    AND wp.wp_image_count >= 5
    AND sm_cr.sm_carrier = 'UPS'
    AND r_sr.r_reason_desc = 'Damaged'
    AND we.web_country = 'United States'
GROUP BY
    s.s_store_name,
    i.i_category,
    td_ss.t_hour,
    sm_cr.sm_carrier,
    r_sr.r_reason_desc,
    we.web_name
ORDER BY total_store_sales_net_paid DESC
LIMIT 100
