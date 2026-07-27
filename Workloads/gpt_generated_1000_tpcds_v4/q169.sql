WITH filtered_returns AS (
    SELECT
        cc.cc_name,
        sm.sm_type,
        td.t_sub_shift,
        hd.hd_vehicle_count,
        r.r_reason_desc,
        cr.cr_return_amount,
        cr.cr_return_tax
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_sub_shift = 'evening'
      AND r.r_reason_id = 'AAAAAAAADAAAAAAA'
      AND hd.hd_vehicle_count >= 2
      AND cc.cc_state = 'CA'
)
SELECT
    cc_name,
    sm_type,
    t_sub_shift,
    hd_vehicle_count,
    r_reason_desc,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_cnt,
    MIN(cr_return_amount) AS min_return_amount,
    MAX(cr_return_amount) AS max_return_amount
FROM filtered_returns
GROUP BY
    cc_name,
    sm_type,
    t_sub_shift,
    hd_vehicle_count,
    r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
