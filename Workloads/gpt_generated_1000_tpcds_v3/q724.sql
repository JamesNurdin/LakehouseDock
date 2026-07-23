SELECT
    cc_a.cc_name AS call_center_name,
    cc_b.cc_division AS call_center_division,
    sm_a.sm_type AS ship_mode_type,
    sm_b.sm_carrier AS ship_mode_carrier,
    r_a.r_reason_desc AS reason_desc_main,
    r_b.r_reason_desc AS reason_desc_sub,
    r_c.r_reason_desc AS reason_desc_extra1,
    r_d.r_reason_desc AS reason_desc_extra2,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders
FROM
    tpcds.catalog_returns AS cr
    JOIN tpcds.call_center AS cc_a
        ON cr.cr_call_center_sk = cc_a.cc_call_center_sk
    JOIN tpcds.call_center AS cc_b
        ON cr.cr_call_center_sk = cc_b.cc_call_center_sk
    JOIN tpcds.ship_mode AS sm_a
        ON cr.cr_ship_mode_sk = sm_a.sm_ship_mode_sk
    JOIN tpcds.ship_mode AS sm_b
        ON cr.cr_ship_mode_sk = sm_b.sm_ship_mode_sk
    JOIN tpcds.reason AS r_a
        ON cr.cr_reason_sk = r_a.r_reason_sk
    JOIN tpcds.reason AS r_b
        ON cr.cr_reason_sk = r_b.r_reason_sk
    JOIN tpcds.web_returns AS wr
        ON wr.wr_reason_sk = r_a.r_reason_sk
    JOIN tpcds.reason AS r_c
        ON wr.wr_reason_sk = r_c.r_reason_sk
    JOIN tpcds.reason AS r_d
        ON wr.wr_reason_sk = r_d.r_reason_sk
GROUP BY
    cc_a.cc_name,
    cc_b.cc_division,
    sm_a.sm_type,
    sm_b.sm_carrier,
    r_a.r_reason_desc,
    r_b.r_reason_desc,
    r_c.r_reason_desc,
    r_d.r_reason_desc
ORDER BY
    total_net_loss DESC
LIMIT 100
