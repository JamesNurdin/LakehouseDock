SELECT
    d.d_year,
    i.i_category,
    sm.sm_type,
    ws_site.web_name,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    r.r_reason_desc,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    AVG(ws.ws_net_profit) AS avg_profit,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    COUNT(DISTINCT wr.wr_return_quantity) AS web_return_cnt
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
WHERE d.d_year = 2001
GROUP BY
    d.d_year,
    i.i_category,
    sm.sm_type,
    ws_site.web_name,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    r.r_reason_desc
ORDER BY total_net_paid DESC
LIMIT 100
