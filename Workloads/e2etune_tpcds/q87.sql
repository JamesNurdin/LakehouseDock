WITH sales_agg AS (
  SELECT
    d.d_year,
    ib.ib_income_band_sk,
    ib.ib_upper_bound,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND ss.ss_quantity > 5
    AND hd.hd_vehicle_count >= 2
  GROUP BY d.d_year, ib.ib_income_band_sk, ib.ib_upper_bound
),
returns_agg AS (
  SELECT
    d.d_year,
    ib.ib_income_band_sk,
    SUM(cr.cr_net_loss) AS total_return_loss,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND cr.cr_return_amt_inc_tax > 200
    AND hd.hd_vehicle_count >= 2
  GROUP BY d.d_year, ib.ib_income_band_sk
)
SELECT
  s.d_year,
  s.ib_income_band_sk,
  s.ib_upper_bound,
  s.total_net_profit,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
  s.distinct_customers,
  RANK() OVER (PARTITION BY s.d_year ORDER BY (s.total_net_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.d_year = r.d_year AND s.ib_income_band_sk = r.ib_income_band_sk
ORDER BY s.d_year, profit_rank
