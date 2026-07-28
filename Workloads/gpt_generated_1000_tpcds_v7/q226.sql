WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_refunded_cdemo_sk,
        cr.cr_returned_time_sk,
        cc.cc_name,
        cc.cc_state,
        cc.cc_rec_start_date,
        cc.cc_rec_end_date,
        cp.cp_department,
        sm.sm_type,
        cd.cd_credit_rating,
        cd.cd_gender,
        td.t_hour
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cc.cc_state = 'CA'
      AND cp.cp_department = 'Electronics'
      AND sm.sm_type = 'OVERNIGHT'
      AND cd.cd_credit_rating = 'Good'
      AND td.t_hour BETWEEN 9 AND 17
      AND cr.cr_return_amount > 100.00
      AND cc.cc_rec_start_date >= DATE '2002-01-01'
      AND cc.cc_rec_end_date <= DATE '2003-12-31'
)
SELECT
    cc_name,
    cp_department,
    sm_type,
    cd_gender,
    t_hour,
    COUNT(*) AS return_count,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_quantity) AS avg_return_qty,
    MIN(cr_return_amount) AS min_return_amount,
    MAX(cr_return_amount) AS max_return_amount
FROM filtered_returns fr
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_returned_time_sk = fr.cr_returned_time_sk
      AND wr.wr_refunded_cdemo_sk = fr.cr_refunded_cdemo_sk
)
GROUP BY cc_name, cp_department, sm_type, cd_gender, t_hour
ORDER BY total_return_amount DESC
