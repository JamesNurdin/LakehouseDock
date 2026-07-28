WITH store_ret AS (
    SELECT
        t.t_shift AS shift,
        r.r_reason_desc AS reason,
        SUM(sr.sr_return_amt) AS return_amt
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_quantity > 0
    GROUP BY GROUPING SETS ((t.t_shift, r.r_reason_desc), (t.t_shift), ())
),
catalog_ret AS (
    SELECT
        t.t_shift AS shift,
        r.r_reason_desc AS reason,
        SUM(cr.cr_return_amount) AS return_amt
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_quantity > 0
    GROUP BY GROUPING SETS ((t.t_shift, r.r_reason_desc), (t.t_shift), ())
),
combined AS (
    SELECT shift, reason, return_amt FROM store_ret
    UNION ALL
    SELECT shift, reason, return_amt FROM catalog_ret
)
SELECT
    shift,
    reason,
    SUM(return_amt) AS total_return_amount,
    CASE WHEN SUM(return_amt) > 500 THEN 'High' ELSE 'Low' END AS amount_category,
    CASE WHEN SUM(return_amt) > (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_return_quantity > 0
        ) THEN 'Above Avg Catalog' ELSE 'Below Avg Catalog' END AS comparison_to_catalog_avg
FROM combined
GROUP BY ROLLUP (shift, reason)
ORDER BY shift ASC, reason ASC
LIMIT 100
