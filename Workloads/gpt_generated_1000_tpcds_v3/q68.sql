SELECT
    wsite.web_name,
    cc.cc_name,
    td.t_meal_time,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    MIN(ws.ws_net_paid) AS min_net_paid,
    MAX(ws.ws_net_paid) AS max_net_paid,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_fee) AS total_catalog_fee,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS overall_avg_net_profit
FROM web_sales ws
JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = td.t_time_sk
    AND cr.cr_refunded_customer_sk = c.c_customer_sk
    AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN store_returns sr
    ON sr.sr_return_time_sk = td.t_time_sk
    AND sr.sr_customer_sk = c.c_customer_sk
    AND sr.sr_cdemo_sk = cd.cd_demo_sk
    AND sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN web_returns wr
    ON wr.wr_returned_time_sk = td.t_time_sk
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
    AND wr.wr_refunded_customer_sk = c.c_customer_sk
    AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    cc.cc_state = 'CA'
    AND cc.cc_gmt_offset = -5.00
    AND td.t_meal_time = 'lunch'
    AND wsite.web_mkt_id IN (1, 3, 5)
    AND wp.wp_url LIKE '%example%'
    AND c.c_preferred_cust_flag = 'Y'
    AND ib.ib_lower_bound >= 60000
    AND ws.ws_quantity > 1
    AND cr.cr_store_credit > 10.0
    AND sr.sr_return_quantity > 0
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        JOIN call_center cc2
            ON cr2.cr_call_center_sk = cc2.cc_call_center_sk
        WHERE cr2.cr_returned_time_sk = td.t_time_sk
          AND cr2.cr_refunded_customer_sk = c.c_customer_sk
          AND cc2.cc_class = 'MKT'
          AND cr2.cr_return_amount > 100
    )
GROUP BY
    wsite.web_name,
    cc.cc_name,
    td.t_meal_time
ORDER BY total_net_paid DESC
LIMIT 100
