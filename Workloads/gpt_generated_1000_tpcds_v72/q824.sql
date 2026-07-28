SELECT
    cc.cc_name,
    cp.cp_department,
    p.p_promo_name,
    td.t_hour,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(sr.sr_refunded_cash) AS total_refunds,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    CASE WHEN SUM(ws.ws_net_paid) > SUM(sr.sr_refunded_cash) THEN 'Profit' ELSE 'Loss' END AS profit_indicator
FROM
    time_dim td
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer ws_cust
        ON ws.ws_bill_customer_sk = ws_cust.c_customer_sk
    JOIN household_demographics ws_hdemo
        ON ws.ws_bill_hdemo_sk = ws_hdemo.hd_demo_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p2
        ON cs.cs_promo_sk = p2.p_promo_sk
    JOIN customer cs_cust
        ON cs.cs_bill_customer_sk = cs_cust.c_customer_sk
    JOIN household_demographics cs_hdemo
        ON cs.cs_bill_hdemo_sk = cs_hdemo.hd_demo_sk
    CROSS JOIN LATERAL (
        SELECT *
        FROM store_returns sr
        WHERE sr.sr_return_time_sk = td.t_time_sk
    ) sr
GROUP BY
    cc.cc_name,
    cp.cp_department,
    p.p_promo_name,
    td.t_hour
ORDER BY
    total_web_sales DESC
LIMIT 100
