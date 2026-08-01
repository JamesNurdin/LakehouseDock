/* Goal: Compare return amounts by reason for large vs small return quantities, include subtotals, categorize volume, and show average return amount per reason. */
WITH unified AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        r.r_reason_sk   AS reason_sk,
        SUM(cr.cr_return_amount)      AS total_return_amount,
        COUNT(*)                      AS return_cnt,
        CASE WHEN COUNT(*) > 100 THEN 'High' ELSE 'Low' END AS volume_category
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_quantity > 5
      AND r.r_reason_desc LIKE '%price%'
    GROUP BY GROUPING SETS ((r.r_reason_desc, r.r_reason_sk), ())

    UNION ALL

    SELECT
        r.r_reason_desc AS reason_desc,
        r.r_reason_sk   AS reason_sk,
        SUM(cr.cr_return_amount)      AS total_return_amount,
        COUNT(*)                      AS return_cnt,
        CASE WHEN COUNT(*) > 100 THEN 'High' ELSE 'Low' END AS volume_category
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_quantity <= 5
      AND r.r_reason_desc LIKE '%warranty%'
    GROUP BY GROUPING SETS ((r.r_reason_desc, r.r_reason_sk), ())
)
SELECT
    u.reason_desc,
    u.reason_sk,
    u.total_return_amount,
    u.return_cnt,
    u.volume_category,
    (SELECT AVG(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_reason_sk = u.reason_sk) AS avg_return_amount_by_reason
FROM unified u
ORDER BY u.total_return_amount DESC
LIMIT 100
