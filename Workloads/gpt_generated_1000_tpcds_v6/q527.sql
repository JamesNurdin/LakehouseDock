WITH returns_low_hdemo AS (
    SELECT
        r.r_reason_desc,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        'HDemo_0_2000' AS segment
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returning_hdemo_sk BETWEEN 0 AND 2000
    GROUP BY r.r_reason_desc
    HAVING SUM(cr.cr_return_amt_inc_tax) > 5000
),
returns_mid_hdemo AS (
    SELECT
        r.r_reason_desc,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        'HDemo_2001_4000' AS segment
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returning_hdemo_sk BETWEEN 2001 AND 4000
    GROUP BY r.r_reason_desc
    HAVING SUM(cr.cr_return_amt_inc_tax) > 5000
)
SELECT
    r_reason_desc,
    total_return_amount,
    avg_return_qty,
    segment
FROM returns_low_hdemo
UNION ALL
SELECT
    r_reason_desc,
    total_return_amount,
    avg_return_qty,
    segment
FROM returns_mid_hdemo
ORDER BY total_return_amount DESC
LIMIT 100
