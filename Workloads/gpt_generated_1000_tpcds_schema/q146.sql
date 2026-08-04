WITH avg_return AS (
    SELECT avg(cr_return_amount) AS avg_amt
    FROM catalog_returns
)
SELECT
    r.r_reason_desc AS reason,
    SUM(cr.cr_return_amount) AS total_return,
    d.d_year AS year,
    cc.cc_name AS call_center_name
FROM catalog_returns AS cr
TABLESAMPLE BERNOULLI (10)
JOIN reason AS r ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim AS d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center AS cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE d.d_year = 1912
  AND cr.cr_return_amount > (SELECT avg_amt FROM avg_return)
GROUP BY r.r_reason_desc, d.d_year, cc.cc_name

UNION ALL

SELECT
    r.r_reason_desc AS reason,
    SUM(cr.cr_return_amount) AS total_return,
    d.d_year AS year,
    cc.cc_name AS call_center_name
FROM catalog_returns AS cr
TABLESAMPLE BERNOULLI (10)
JOIN reason AS r ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim AS d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center AS cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE d.d_year = 1914
  AND cr.cr_return_amount > (SELECT avg_amt FROM avg_return)
GROUP BY r.r_reason_desc, d.d_year, cc.cc_name

ORDER BY total_return DESC
LIMIT 100
