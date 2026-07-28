WITH
  store_returns_monthly AS (
    SELECT
      d.d_year AS year,
      d.d_month_seq AS month_seq,
      SUM(sr.sr_return_amt_inc_tax) AS total_return,
      'store' AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_return_amt_inc_tax > 0
      AND d.d_year >= 2000
    GROUP BY d.d_year, d.d_month_seq
  ),
  web_returns_monthly AS (
    SELECT
      d.d_year AS year,
      d.d_month_seq AS month_seq,
      SUM(wr.wr_return_amt_inc_tax) AS total_return,
      'web' AS channel
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE wr.wr_return_amt_inc_tax > 0
      AND d.d_year >= 2000
    GROUP BY d.d_year, d.d_month_seq
  )
SELECT
  combined.year,
  combined.month_seq,
  combined.channel,
  combined.total_return,
  CASE WHEN combined.total_return >= 5000 THEN 'High' ELSE 'Low' END AS return_category
FROM (
  SELECT * FROM store_returns_monthly
  UNION ALL
  SELECT * FROM web_returns_monthly
) AS combined
ORDER BY combined.year DESC,
         combined.month_seq DESC,
         combined.total_return DESC
LIMIT 100
