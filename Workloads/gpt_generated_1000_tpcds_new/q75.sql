WITH
  sales_agg AS (
    SELECT
      hd.hd_demo_sk,
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      SUM(cs.cs_net_profit) AS total_amount,
      ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS rn,
      (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS overall_avg_net_profit
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential = '1001-5000'
      AND ib.ib_lower_bound >= 100000
    GROUP BY hd.hd_demo_sk, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
  ),
  returns_agg AS (
    SELECT
      hd.hd_demo_sk,
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      SUM(sr.sr_net_loss) AS total_amount,
      ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY SUM(sr.sr_net_loss) DESC) AS rn,
      (SELECT AVG(sr2.sr_fee) FROM store_returns sr2) AS overall_avg_fee
    FROM store_returns sr
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_fee > 30
      AND ib.ib_upper_bound <= 200000
    GROUP BY hd.hd_demo_sk, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
  )
SELECT
  hd_demo_sk,
  ib_income_band_sk,
  ib_lower_bound,
  ib_upper_bound,
  total_amount,
  'sales' AS metric_type,
  overall_avg_net_profit AS overall_metric
FROM sales_agg
WHERE rn <= 5
UNION ALL
SELECT
  hd_demo_sk,
  ib_income_band_sk,
  ib_lower_bound,
  ib_upper_bound,
  total_amount,
  'returns' AS metric_type,
  overall_avg_fee AS overall_metric
FROM returns_agg
WHERE rn <= 5
ORDER BY ib_income_band_sk, metric_type, total_amount DESC
LIMIT 100
