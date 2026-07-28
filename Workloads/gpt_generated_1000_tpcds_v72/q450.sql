WITH ws_agg AS (
    SELECT
        ws.ws_ship_mode_sk,
        ws.ws_bill_customer_sk,
        ws.ws_sold_time_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid,
        SUM(ws.ws_ext_ship_cost) AS total_ship_cost
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year > 1970
    GROUP BY ws.ws_ship_mode_sk, ws.ws_bill_customer_sk, ws.ws_sold_time_sk, ws.ws_web_site_sk
)
SELECT
    cc.cc_name,
    cc.cc_county,
    r.r_reason_desc,
    sm1.sm_type AS return_ship_type,
    sm2.sm_type AS sales_ship_type,
    t1.t_hour AS return_hour,
    t2.t_hour AS sales_hour,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(ws_agg.total_net_paid) AS total_sales_net_paid,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    COUNT(DISTINCT ws_agg.ws_sold_time_sk) AS distinct_sales_time_slots,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = r.r_reason_sk
    ) AS avg_return_amount_by_reason
FROM catalog_returns cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm1 ON cr.cr_ship_mode_sk = sm1.sm_ship_mode_sk
JOIN time_dim t1 ON cr.cr_returned_time_sk = t1.t_time_sk
JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN ws_agg ON ws_agg.ws_bill_customer_sk = c_refund.c_customer_sk
JOIN ship_mode sm2 ON ws_agg.ws_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN time_dim t2 ON ws_agg.ws_sold_time_sk = t2.t_time_sk
JOIN web_site ws ON ws_agg.ws_web_site_sk = ws.web_site_sk
GROUP BY
    cc.cc_name,
    cc.cc_county,
    r.r_reason_desc,
    sm1.sm_type,
    sm2.sm_type,
    t1.t_hour,
    t2.t_hour,
    r.r_reason_sk
ORDER BY total_net_loss DESC
LIMIT 100
