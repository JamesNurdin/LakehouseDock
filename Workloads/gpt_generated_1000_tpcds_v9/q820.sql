/*
Goal: Analyze sales performance and return loss by ship mode, call center, and time shift, joining all selected TPC‑DS tables with multiple aliases to demonstrate deep joins.
*/
SELECT
    sm.sm_ship_mode_id,
    sm.sm_type,
    cc.cc_name,
    cp.cp_department,
    ws_time.t_shift      AS sales_shift,
    cr_time.t_shift      AS return_shift,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_net_paid)         AS total_sales_net_paid,
    SUM(ws.ws_net_profit)       AS total_sales_profit,
    SUM(cr.cr_return_amount)    AS total_return_amount,
    SUM(cr.cr_net_loss)         AS total_return_loss
FROM ship_mode sm
JOIN catalog_returns cr
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_sales ws
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse cr_wh
    ON cr.cr_warehouse_sk = cr_wh.w_warehouse_sk
JOIN warehouse ws_wh
    ON ws.ws_warehouse_sk = ws_wh.w_warehouse_sk
JOIN time_dim cr_time
    ON cr.cr_returned_time_sk = cr_time.t_time_sk
JOIN time_dim ws_time
    ON ws.ws_sold_time_sk = ws_time.t_time_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_type,
    cc.cc_name,
    cp.cp_department,
    ws_time.t_shift,
    cr_time.t_shift
ORDER BY total_sales_amount DESC
LIMIT 100
