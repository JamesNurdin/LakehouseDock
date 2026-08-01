WITH store_ret_filtered AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_reason_sk,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        d.d_year,
        r.r_reason_desc,
        p.p_channel_details,
        p.p_response_target
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE
        REGEXP_LIKE(r.r_reason_desc, '(?i)damage|defect|lost')
        AND r.r_reason_desc LIKE '%damage%'
        AND REGEXP_LIKE(p.p_channel_details, '(?i)email')
        AND p.p_response_target > 1000
        AND t.t_meal_time LIKE 'Lun%'
        AND EXISTS (
            SELECT 1
            FROM promotion p2
            JOIN date_dim d2 ON p2.p_start_date_sk = d2.d_date_sk
            WHERE d2.d_date_sk = sr.sr_returned_date_sk
              AND REGEXP_LIKE(p2.p_channel_details, '(?i)email')
        )
)
SELECT
    sr_ret.r_reason_desc AS reason_desc,
    sr_ret.d_year AS return_year,
    COUNT(*) AS store_return_cnt,
    SUM(sr_ret.sr_net_loss) AS total_net_loss,
    CONCAT('Reason: ', sr_ret.r_reason_desc) AS reason_full,
    SUBSTRING(MIN(sr_ret.p_channel_details), 1, 30) AS promo_channel_snippet,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr
        JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
        JOIN date_dim dcr ON cr.cr_returned_date_sk = dcr.d_date_sk
        WHERE r2.r_reason_desc = sr_ret.r_reason_desc
          AND dcr.d_year = sr_ret.d_year
    ) AS catalog_return_cnt_year
FROM store_ret_filtered sr_ret
GROUP BY
    sr_ret.r_reason_desc,
    sr_ret.d_year
ORDER BY total_net_loss DESC
LIMIT 100
