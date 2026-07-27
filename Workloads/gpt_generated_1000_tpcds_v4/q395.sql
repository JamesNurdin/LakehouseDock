WITH
  sales_monthly AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      SUM(cs.cs_net_profit) AS total_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
  ),
  returns_monthly AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      SUM(sr.sr_net_loss) AS total_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
  )
SELECT
  sm.d_year,
  sm.d_month_seq,
  'catalog_sales' AS source,
  sm.total_amount AS amount
FROM sales_monthly sm
UNION ALL
SELECT
  rm.d_year,
  rm.d_month_seq,
  'store_returns' AS source,
  rm.total_amount AS amount
FROM returns_monthly rm
ORDER BY d_year, d_month_seq, source
