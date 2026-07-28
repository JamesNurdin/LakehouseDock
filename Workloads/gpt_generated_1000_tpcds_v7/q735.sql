WITH catalog AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        CAST('catalog' AS varchar) AS source,
        cr.cr_return_amount AS return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
),
store AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        CAST('store' AS varchar) AS source,
        sr.sr_return_amt AS return_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
),
combined AS (
    SELECT reason_desc, source, return_amount FROM catalog
    UNION ALL
    SELECT reason_desc, source, return_amount FROM store
)
SELECT
    reason_desc,
    source,
    SUM(return_amount) AS total_return_amount
FROM combined
GROUP BY GROUPING SETS (
    (reason_desc, source),
    (reason_desc),
    (source),
    ()
)
ORDER BY
    CASE WHEN reason_desc IS NULL THEN 1 ELSE 0 END,
    reason_desc,
    source
