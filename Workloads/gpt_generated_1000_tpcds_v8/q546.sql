WITH sales_agg AS (
  SELECT
    s.s_state AS region,
    d.d_year AS year,
    'sales' AS metric,
    SUM(ss.ss_net_paid) AS amount,
    SUM(ss.ss_net_profit) AS profit,
    COUNT(*) AS txn_cnt
  FROM (
    SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)
  ) ss
  FULL OUTER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year = (SELECT max(d_year) FROM date_dim)
    AND EXISTS (
      SELECT 1 FROM income_band ib2
      WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk
        AND ib2.ib_lower_bound > 30000
    )
  GROUP BY GROUPING SETS (
    (s.s_state, d.d_year),
    (s.s_state),
    ()
  )
),
returns_agg AS (
  SELECT
    CAST(NULL AS varchar) AS region,
    d.d_year AS year,
    'returns' AS metric,
    SUM(cr.cr_return_amount) AS amount,
    SUM(cr.cr_net_loss) AS profit,
    COUNT(*) AS txn_cnt
  FROM catalog_returns cr
  LEFT JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  LEFT JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
  LEFT JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year = (SELECT max(d_year) FROM date_dim)
    AND ib.ib_upper_bound < 80000
  GROUP BY GROUPING SETS (
    (d.d_year),
    ()
  )
)
SELECT
  region,
  year,
  metric,
  amount,
  profit,
  txn_cnt,
  SUM(amount) OVER (PARTITION BY region ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_amount
FROM (
  SELECT * FROM sales_agg
  UNION
  SELECT * FROM returns_agg
) AS combined
ORDER BY region NULLS LAST, year DESC, metric
LIMIT 100
