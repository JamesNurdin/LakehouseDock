WITH cat_ret AS (
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    'catalog' AS source
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_carrier = 'DIAMOND'
    AND d.d_year = 2001
  GROUP BY d.d_year, d.d_month_seq
  HAVING SUM(cr.cr_return_amount) > 500
),
web_ret AS (
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(*) AS return_cnt,
    'web' AS source
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, d.d_month_seq
  HAVING SUM(wr.wr_return_amt) > 500
),
combined AS (
  SELECT year, month_seq, total_return_amount, return_cnt, source
  FROM cat_ret
  UNION ALL
  SELECT year, month_seq, total_return_amount, return_cnt, source
  FROM web_ret
)
SELECT
  year,
  month_seq,
  total_return_amount,
  return_cnt,
  source,
  ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_return_amount DESC) AS rn
FROM combined
WHERE total_return_amount > 1000
ORDER BY year, rn
