WITH reason_agg AS (
    SELECT
        r.r_reason_id,
        SUM(cr.cr_return_amount) AS overall_return_amount,
        COUNT(*) AS overall_return_cnt
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_id
)
SELECT
    sub.period,
    sub.r_reason_id,
    SUM(sub.cr_return_amount) AS period_return_amount,
    COUNT(*) AS period_return_cnt,
    CASE WHEN SUM(sub.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
    RANK() OVER (PARTITION BY sub.period ORDER BY SUM(sub.cr_return_amount) DESC) AS reason_rank,
    ra.overall_return_amount
FROM (
    SELECT
        'Morning' AS period,
        cr.cr_return_amount,
        cr.cr_reason_sk,
        r.r_reason_id
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE td.t_hour BETWEEN 0 AND 11

    UNION ALL

    SELECT
        'Evening' AS period,
        cr.cr_return_amount,
        cr.cr_reason_sk,
        r.r_reason_id
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE td.t_hour BETWEEN 12 AND 23
) AS sub
JOIN reason_agg ra ON sub.r_reason_id = ra.r_reason_id
GROUP BY
    sub.period,
    sub.r_reason_id,
    ra.overall_return_amount
ORDER BY
    sub.period,
    reason_rank
LIMIT 100
