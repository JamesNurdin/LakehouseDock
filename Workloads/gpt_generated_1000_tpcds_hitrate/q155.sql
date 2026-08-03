WITH
  store_daily AS (
    SELECT
      d.d_date AS return_date,
      SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
      'store' AS return_source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
  ),
  catalog_daily AS (
    SELECT
      d.d_date AS return_date,
      SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
      'catalog' AS return_source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
  ),
  combined AS (
    SELECT * FROM store_daily
    UNION ALL
    SELECT * FROM catalog_daily
  ),
  avg_return AS (
    SELECT AVG(total_return_amount) AS avg_amount FROM combined
  )
SELECT
  c.return_date,
  c.return_source,
  c.total_return_amount,
  CASE
    WHEN c.total_return_amount > (SELECT avg_amount FROM avg_return) THEN 'above_avg'
    ELSE 'below_avg'
  END AS avg_comparison,
  LAG(c.total_return_amount) OVER (PARTITION BY c.return_source ORDER BY c.return_date) AS prev_day_amount
FROM combined c
ORDER BY c.return_date ASC, c.return_source
