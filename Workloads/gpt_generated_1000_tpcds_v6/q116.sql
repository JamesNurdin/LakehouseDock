WITH rc AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_order_number,
        cr.cr_call_center_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        cr.cr_returning_cdemo_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
)
SELECT
    d.d_year,
    cc.cc_name,
    sm.sm_type,
    w.w_city,
    s.s_store_name,
    cd.cd_gender,
    SUM(rc.cr_return_amount) AS total_return_amount,
    AVG(rc.cr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT rc.cr_order_number) AS distinct_orders,
    MIN(rc.cr_return_amount) AS min_return_amount,
    MAX(rc.cr_return_amount) AS max_return_amount
FROM rc
JOIN date_dim d ON rc.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc ON rc.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON rc.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON rc.cr_warehouse_sk = w.w_warehouse_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN customer_demographics cd ON rc.cr_returning_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year = 2001
  AND cc.cc_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND w.w_suite_number = 'Suite 470'
  AND cd.cd_gender = 'F'
GROUP BY d.d_year, cc.cc_name, sm.sm_type, w.w_city, s.s_store_name, cd.cd_gender
ORDER BY total_return_amount DESC
LIMIT 100
