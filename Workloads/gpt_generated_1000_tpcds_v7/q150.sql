SELECT
  d.d_year,
  d.d_month_seq,
  SUM(c.cr_return_amount) AS total_return_amount,
  COUNT(*) AS return_cnt
FROM catalog_returns AS c
JOIN date_dim AS d
  ON c.cr_returned_date_sk = d.d_date_sk
WHERE d.d_current_month = 'Y'
  AND c.cr_reversed_charge < 100.00
GROUP BY d.d_year, d.d_month_seq
ORDER BY total_return_amount DESC
LIMIT 10
