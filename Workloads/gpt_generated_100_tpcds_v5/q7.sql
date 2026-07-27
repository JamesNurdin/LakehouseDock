WITH
  store_sales_daily AS (
    SELECT
      d.d_date AS transaction_date,
      SUM(ss.ss_net_paid_inc_tax) AS total_amount,
      'store_sales' AS source
    FROM
      tpcds.store_sales ss
    JOIN
      tpcds.date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2022
      AND d.d_current_week = 'N'
      AND ss.ss_promo_sk IN (194, 239, 602)
    GROUP BY
      d.d_date
  ),
  web_returns_daily AS (
    SELECT
      d.d_date AS transaction_date,
      SUM(wr.wr_return_amt) AS total_amount,
      'web_returns' AS source
    FROM
      tpcds.web_returns wr
    JOIN
      tpcds.date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2022
      AND d.d_current_week = 'N'
      AND wr.wr_return_amt > 100.00
    GROUP BY
      d.d_date
  )
SELECT
  transaction_date,
  total_amount,
  source
FROM (
  SELECT transaction_date, total_amount, source FROM store_sales_daily
  UNION ALL
  SELECT transaction_date, total_amount, source FROM web_returns_daily
) combined
ORDER BY
  transaction_date DESC,
  total_amount DESC
LIMIT 100
