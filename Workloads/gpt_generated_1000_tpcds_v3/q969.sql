SELECT
    i.i_category AS category,
    i.i_brand AS brand,
    cp.cp_department AS department,
    p.p_promo_name AS promo_name,
    sm_ws.sm_type AS ship_mode_type,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amount_inc_tax,
    CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN household_demographics hd_cr_refunded ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
JOIN household_demographics hd_cr_returning ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN item i_wr ON wr.wr_item_sk = i_wr.i_item_sk
JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM web_site ws2
    WHERE ws2.web_site_sk = ws.ws_web_site_sk
      AND ws2.web_country = 'United States'
)
GROUP BY
    i.i_category,
    i.i_brand,
    cp.cp_department,
    p.p_promo_name,
    sm_ws.sm_type
ORDER BY total_net_profit DESC
LIMIT 100
