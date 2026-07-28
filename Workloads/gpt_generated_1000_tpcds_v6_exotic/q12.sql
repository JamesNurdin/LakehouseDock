WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_call_center_sk,
        d.d_year,
        d.d_fy_week_seq,
        dm.cd_credit_rating,
        dm.cd_dep_employed_count,
        sm.sm_type,
        r.r_reason_desc,
        cr.cr_reason_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics dm ON cr.cr_returning_cdemo_sk = dm.cd_demo_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_fy_week_seq BETWEEN 5 AND 15
      AND d.d_current_day = 'N'
      AND dm.cd_credit_rating = 'Good'
      AND dm.cd_dep_employed_count >= 2
      AND sm.sm_type = 'Air'
      AND cr.cr_call_center_sk IN (1, 2, 14)
)
SELECT
    fr.d_year,
    fr.r_reason_desc,
    fr.sm_type,
    COUNT(*) AS total_returns,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    MIN(fr.cr_return_amount) AS min_return_amount,
    MAX(fr.cr_return_amount) AS max_return_amount
FROM filtered_returns fr
WHERE NOT EXISTS (
    SELECT 1
    FROM reason r2
    JOIN catalog_returns cr2 ON cr2.cr_reason_sk = r2.r_reason_sk
    JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
    WHERE r2.r_reason_desc LIKE '%Damaged%'
      AND cr2.cr_net_loss > 1000
      AND r2.r_reason_sk = fr.cr_reason_sk
)
GROUP BY fr.d_year, fr.r_reason_desc, fr.sm_type
HAVING COUNT(*) >= 10
ORDER BY total_return_amount DESC
LIMIT 100
