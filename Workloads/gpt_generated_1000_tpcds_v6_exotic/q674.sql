SELECT
    s.s_city,
    we.web_market_manager,
    cc.cc_name,
    SUM(ss.ss_net_profit) AS total_store_net_profit,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    COUNT(cr.cr_order_number) AS total_return_orders
FROM
    catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN warehouse wh_cr ON cr.cr_warehouse_sk = wh_cr.w_warehouse_sk
    JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    -- store_sales and related dimensions
    JOIN store_sales ss ON ss.ss_customer_sk = c_refunded.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    -- web_sales and related dimensions
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c_refunded.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN warehouse wh_ws ON ws.ws_warehouse_sk = wh_ws.w_warehouse_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN income_band ib ON hd_ws_bill.hd_income_band_sk = ib.ib_income_band_sk
    -- time dimension for catalog_returns
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
WHERE
    s.s_state = 'CA'
GROUP BY
    s.s_city,
    we.web_market_manager,
    cc.cc_name
ORDER BY
    total_store_net_profit DESC
LIMIT 100
