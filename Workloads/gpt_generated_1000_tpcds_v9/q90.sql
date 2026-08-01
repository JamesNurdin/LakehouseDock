SELECT
    sm_cr.sm_ship_mode_id AS ship_mode,
    d_ret.d_year AS return_year,
    cd_refunded.cd_gender AS gender,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_paid) AS total_sales,
    CASE WHEN SUM(ws.ws_net_paid) - SUM(cr.cr_return_amount) > 0 THEN 'Profit' ELSE 'Loss' END AS net_status
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN customer cust_refunded
    ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN income_band ib_refunded
    ON hd_refunded.hd_income_band_sk = ib_refunded.ib_income_band_sk
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN warehouse w_cr
    ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN customer cust_returning
    ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
JOIN web_sales ws
    ON ws.ws_ship_mode_sk = sm_cr.sm_ship_mode_sk
   AND ws.ws_warehouse_sk = w_cr.w_warehouse_sk
   AND ws.ws_sold_date_sk = d_ret.d_date_sk
   AND ws.ws_sold_time_sk = t_ret.t_time_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
GROUP BY ROLLUP (sm_cr.sm_ship_mode_id, d_ret.d_year, cd_refunded.cd_gender)
LIMIT 100
