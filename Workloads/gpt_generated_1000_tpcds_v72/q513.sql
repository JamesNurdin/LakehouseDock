/* goal: Compare aggregated web return amounts between customers who were refunded and those who were returning, broken down by education status, while filtering on fee ranges, excluding low‑fee returning customers, and incorporating per‑date fee averages via a lateral join. */
WITH refunded_agg AS (
  SELECT
    cd.cd_education_status AS education_status,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
    COUNT(*) AS return_cnt,
    AVG(wr.wr_fee) AS avg_fee
  FROM web_returns wr
  JOIN customer_demographics cd
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE wr.wr_fee > 30
  GROUP BY cd.cd_education_status
)
SELECT
  ra.education_status,
  ra.total_return_inc_tax,
  ra.return_cnt,
  ra.avg_fee,
  'refunded' AS role
FROM refunded_agg ra
WHERE NOT EXISTS (
  SELECT 1
  FROM web_returns wr_ex
  JOIN customer_demographics cd_ex
    ON wr_ex.wr_returning_cdemo_sk = cd_ex.cd_demo_sk
  WHERE cd_ex.cd_education_status = ra.education_status
    AND wr_ex.wr_fee < 20
)
UNION ALL
SELECT
  cd.cd_education_status AS education_status,
  SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
  COUNT(*) AS return_cnt,
  avg_fee_by_date.avg_fee_date AS avg_fee,
  'returning' AS role
FROM web_returns wr
JOIN customer_demographics cd
  ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
CROSS JOIN LATERAL (
  SELECT AVG(wr2.wr_fee) AS avg_fee_date
  FROM web_returns wr2
  WHERE wr2.wr_returned_date_sk = wr.wr_returned_date_sk
) avg_fee_by_date
WHERE wr.wr_fee BETWEEN 10 AND 25
GROUP BY cd.cd_education_status, avg_fee_by_date.avg_fee_date
ORDER BY total_return_inc_tax DESC
LIMIT 100
