WITH catalog_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        'Catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
    GROUP BY r.r_reason_desc
    HAVING SUM(cr.cr_return_amount) > 1000
),
web_ret AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_return_amt) AS total_return_amount,
        'Web' AS source
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
    GROUP BY r.r_reason_desc
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT reason_desc,
       total_return_amount,
       source
FROM catalog_ret
UNION ALL
SELECT reason_desc,
       total_return_amount,
       source
FROM web_ret
ORDER BY total_return_amount DESC
LIMIT 100
