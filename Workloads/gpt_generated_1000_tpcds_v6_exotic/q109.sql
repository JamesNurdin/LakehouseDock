WITH joined_data AS (
    SELECT 
        cr.cr_return_amount,
        dd.d_year,
        cc.cc_state,
        sm.sm_type,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE dd.d_year BETWEEN 2001 AND 2002
)
SELECT
    d_year,
    cc_state,
    sm_type,
    SUM(total_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt
FROM (
    SELECT DISTINCT
        d_year,
        cc_state,
        sm_type,
        cr_return_amount AS total_return_amount
    FROM joined_data
    WHERE r_reason_desc LIKE '%fit%'
    UNION ALL
    SELECT DISTINCT
        d_year,
        cc_state,
        sm_type,
        cr_return_amount AS total_return_amount
    FROM joined_data
    WHERE sm_type = 'EXPRESS'
) agg
GROUP BY d_year, cc_state, sm_type
HAVING SUM(total_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
