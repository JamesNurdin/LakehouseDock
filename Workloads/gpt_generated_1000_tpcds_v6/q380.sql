WITH cr AS (
    SELECT cr.*
    FROM catalog_returns cr
)
SELECT
    cc.cc_name AS call_center_name,
    wh_cr.w_warehouse_name AS warehouse_name,
    r_cr.r_reason_desc AS catalog_return_reason,
    r_wr.r_reason_desc AS web_return_reason,
    p.p_promo_name AS promotion_name,
    ws_site.web_name AS website_name,
    t_cr.t_hour AS catalog_return_hour,
    t_wr.t_hour AS web_return_hour,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(ws.ws_net_profit) AS total_web_net_profit
FROM catalog_returns cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse wh_cr ON cr.cr_warehouse_sk = wh_cr.w_warehouse_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN item i_cr ON cr.cr_item_sk = i_cr.i_item_sk
-- refunded‑customer dimensions
JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
-- returning‑customer dimensions
JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
-- web sales (order level)
JOIN web_sales ws ON cr.cr_order_number = ws.ws_order_number
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN item i_ws ON ws.ws_item_sk = i_ws.i_item_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN warehouse wh_ws ON ws.ws_warehouse_sk = wh_ws.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
-- additional customer dimensions for web sales (bill side)
JOIN customer c_ws_bill ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
-- ship side dimensions
JOIN customer c_ws_ship ON ws.ws_ship_customer_sk = c_ws_ship.c_customer_sk
JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN customer_demographics cd_ws_ship ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
-- web returns linked by order number
JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN item i_wr ON wr.wr_item_sk = i_wr.i_item_sk
JOIN customer c_wr_refunded ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
JOIN customer c_wr_returning ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
JOIN customer_demographics cd_wr_returning ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
-- promotion‑item link (reuse item table under another alias)
JOIN item i_promo ON p.p_item_sk = i_promo.i_item_sk
GROUP BY
    cc.cc_name,
    wh_cr.w_warehouse_name,
    r_cr.r_reason_desc,
    r_wr.r_reason_desc,
    p.p_promo_name,
    ws_site.web_name,
    t_cr.t_hour,
    t_wr.t_hour
ORDER BY total_catalog_return_amount DESC
LIMIT 100
