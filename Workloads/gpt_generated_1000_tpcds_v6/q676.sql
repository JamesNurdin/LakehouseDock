WITH catalog_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = cr.cr_reason_sk
    )
    GROUP BY r.r_reason_desc
)
SELECT DISTINCT
    combined.reason_desc,
    combined.total_return_amount,
    combined.source
FROM (
    SELECT
        ca.reason_desc,
        ca.total_return_amount,
        'catalog' AS source
    FROM catalog_agg ca
    UNION ALL
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_return_amt) AS total_return_amount,
        'web' AS source
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt > (
        SELECT AVG(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_reason_sk = wr.wr_reason_sk
    )
    GROUP BY r.r_reason_desc
) combined
ORDER BY combined.total_return_amount DESC
LIMIT 100
