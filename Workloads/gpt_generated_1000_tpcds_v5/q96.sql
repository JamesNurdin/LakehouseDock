WITH rc AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_net_loss,
        cr.cr_reversed_charge
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 1000
      AND cr.cr_reversed_charge < 50
      AND cr.cr_return_quantity >= 1
)
SELECT
    cc.cc_company_name,
    sm.sm_carrier,
    cp.cp_department,
    td.t_hour,
    COUNT(rc.cr_returned_time_sk) AS returns_cnt,
    SUM(rc.cr_return_amount) AS total_return_amount,
    AVG(rc.cr_return_tax) AS avg_return_tax,
    MAX(rc.cr_return_amt_inc_tax) AS max_return_inc_tax,
    CASE
        WHEN SUM(rc.cr_return_amount) > 50000 THEN 'HIGH'
        WHEN SUM(rc.cr_return_amount) > 20000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_volume_category
FROM rc
JOIN call_center cc
    ON rc.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON rc.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON rc.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td
    ON rc.cr_returned_time_sk = td.t_time_sk
JOIN customer c_ref
    ON rc.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN household_demographics hd_ref
    ON rc.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
WHERE cc.cc_company_name = 'able'
  AND sm.sm_carrier = 'USPS'
  AND td.t_hour BETWEEN 9 AND 17
GROUP BY
    cc.cc_company_name,
    sm.sm_carrier,
    cp.cp_department,
    td.t_hour
ORDER BY total_return_amount DESC
LIMIT 100
