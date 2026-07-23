SELECT
    i.i_brand,
    i.i_category,
    d_sold.d_year,
    d_sold.d_month_seq,
    sm.sm_ship_mode_id,
    cc.cc_name,
    ws_site.web_name,
    sum(ws.ws_quantity) AS total_quantity_sold,
    sum(ws.ws_net_paid) AS total_net_paid,
    sum(ws.ws_net_profit) AS total_net_profit,
    sum(cr.cr_return_quantity) AS total_return_quantity,
    sum(cr.cr_return_amount) AS total_return_amount,
    sum(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    avg(i.i_current_price) AS avg_current_price
FROM web_sales ws
LEFT JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
LEFT JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
LEFT JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
LEFT JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
LEFT JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sold.d_date_sk
    AND cr.cr_item_sk = i.i_item_sk
    AND cr.cr_returning_customer_sk = c_bill.c_customer_sk
    AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_date_sk = d_sold.d_date_sk
LEFT JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
WHERE d_sold.d_year = 2001
  AND i.i_brand_id = 1001001
GROUP BY
    i.i_brand,
    i.i_category,
    d_sold.d_year,
    d_sold.d_month_seq,
    sm.sm_ship_mode_id,
    cc.cc_name,
    ws_site.web_name
ORDER BY total_net_profit DESC
LIMIT 100
