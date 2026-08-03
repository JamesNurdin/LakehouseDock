/* goal: Analyze store return performance by household vehicle count and income band, focusing on high‑value returns while excluding households with no vehicles and ensuring the households appear in intersecting high‑tax and high‑quantity return sets. */
WITH
  sr_sample AS (
    SELECT
      sr_hdemo_sk,
      sr_return_amt,
      sr_return_tax,
      sr_return_quantity,
      sr_net_loss
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE sr_return_tax > 20.00
      AND sr_return_amt_inc_tax > 150.00
      AND sr_return_quantity >= 2
      AND sr_net_loss < 400.00
  ),
  hd_filtered AS (
    SELECT
      hd_demo_sk,
      hd_income_band_sk,
      hd_vehicle_count,
      hd_dep_count
    FROM household_demographics
    WHERE hd_vehicle_count > 0
      AND hd_dep_count BETWEEN 1 AND 8
  ),
  income_filtered AS (
    SELECT
      ib_income_band_sk,
      ib_lower_bound,
      ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound >= 50000
      AND ib_upper_bound <= 200000
  ),
  intersect_keys AS (
    SELECT sr_hdemo_sk FROM store_returns WHERE sr_return_tax > 30.00
    INTERSECT
    SELECT sr_hdemo_sk FROM store_returns WHERE sr_return_quantity > 3
  )
SELECT
  sr.sr_hdemo_sk,
  hd.hd_vehicle_count,
  ib.ib_lower_bound,
  COUNT(*) AS cnt_returns,
  SUM(sr.sr_return_amt) AS total_return_amt,
  AVG(sr.sr_return_tax) AS avg_return_tax,
  MIN(sr.sr_net_loss) AS min_net_loss,
  MAX(sr.sr_net_loss) AS max_net_loss
FROM sr_sample sr
FULL OUTER JOIN hd_filtered hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_filtered ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE sr.sr_hdemo_sk NOT IN (
        SELECT hd_demo_sk FROM household_demographics WHERE hd_vehicle_count = 0
      )
  AND sr.sr_hdemo_sk IN (SELECT sr_hdemo_sk FROM intersect_keys)
GROUP BY GROUPING SETS (
    (sr.sr_hdemo_sk, hd.hd_vehicle_count, ib.ib_lower_bound),
    (sr.sr_hdemo_sk, ib.ib_lower_bound),
    (hd.hd_vehicle_count, ib.ib_lower_bound),
    ()
  )
ORDER BY total_return_amt DESC
LIMIT 100
