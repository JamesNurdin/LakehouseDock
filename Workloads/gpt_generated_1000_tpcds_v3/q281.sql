SELECT
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    d_sold.d_year,
    SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales_amount,
    SUM(COALESCE(cr.cr_return_amount, 0) + COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(cr.cr_net_loss, 0) - COALESCE(wr.wr_net_loss, 0)) AS net_profit,
    CASE WHEN SUM(COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(cr.cr_net_loss, 0) - COALESCE(wr.wr_net_loss, 0)) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
FROM store_sales AS ss
JOIN date_dim AS d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN item AS i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion AS p ON ss.ss_promo_sk = p.p_promo_sk
JOIN household_demographics AS hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address AS ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk

JOIN web_sales AS ws ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim AS d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN date_dim AS d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN ship_mode AS sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse AS w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN household_demographics AS hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN customer_address AS ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN household_demographics AS hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
JOIN customer_address AS ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN web_page AS wp_ws ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk
JOIN web_site AS ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk

JOIN catalog_returns AS cr ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim AS d_cr_returned ON cr.cr_returned_date_sk = d_cr_returned.d_date_sk
JOIN catalog_page AS cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode AS sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN warehouse AS w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN reason AS r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN household_demographics AS hd_cr_refunded ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
JOIN customer_address AS ca_cr_refunded ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
JOIN household_demographics AS hd_cr_returning ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
JOIN customer_address AS ca_cr_returning ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk

JOIN web_returns AS wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
JOIN date_dim AS d_wr_returned ON wr.wr_returned_date_sk = d_wr_returned.d_date_sk
JOIN reason AS r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN household_demographics AS hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
JOIN customer_address AS ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
JOIN household_demographics AS hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
JOIN customer_address AS ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
JOIN web_page AS wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk

GROUP BY
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END,
    d_sold.d_year
ORDER BY total_sales_amount DESC
LIMIT 100
