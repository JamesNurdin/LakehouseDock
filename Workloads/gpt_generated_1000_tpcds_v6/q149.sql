WITH catalog_returns_2021 AS (
    SELECT r.r_reason_desc AS reason_desc,
           cr.cr_return_amount AS return_amount,
           'Catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2021
      AND cr.cr_return_amount > 0
),
web_returns_2021 AS (
    SELECT r.r_reason_desc AS reason_desc,
           wr.wr_return_amt AS return_amount,
           'Web' AS source
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2021
      AND wr.wr_return_amt > 0
)
SELECT reason_desc,
       source,
       SUM(return_amount) AS total_return_amount
FROM (
    SELECT reason_desc, return_amount, source FROM catalog_returns_2021
    UNION ALL
    SELECT reason_desc, return_amount, source FROM web_returns_2021
) AS combined
GROUP BY reason_desc, source
ORDER BY reason_desc, source
