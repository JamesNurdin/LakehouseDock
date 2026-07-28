SELECT
    cc.cc_name AS call_center_name,
    sm_cr.sm_carrier AS return_ship_carrier,
    td_cr.t_sub_shift AS return_sub_shift,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_profit) AS total_sales_profit,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_sales_orders
FROM
    catalog_returns cr
JOIN time_dim td_cr
    ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN customer cust_ref
    ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer cust_ret
    ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN web_sales ws
    ON cr.cr_order_number = ws.ws_order_number
JOIN time_dim td_ws
    ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN customer ws_bill_cust
    ON ws.ws_bill_customer_sk = ws_bill_cust.c_customer_sk
JOIN customer_demographics ws_bill_cdemo
    ON ws.ws_bill_cdemo_sk = ws_bill_cdemo.cd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM ship_mode sm_check
    WHERE sm_check.sm_ship_mode_sk = cr.cr_ship_mode_sk
      AND sm_check.sm_carrier = 'FEDEX'
)
GROUP BY
    cc.cc_name,
    sm_cr.sm_carrier,
    td_cr.t_sub_shift
HAVING
    SUM(cr.cr_return_amount) > 10000
ORDER BY
    total_return_amount DESC
LIMIT 100
