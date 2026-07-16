SELECT
  hd_ret.hd_income_band_sk AS returning_income_band,
  hd_ret.hd_vehicle_count AS returning_vehicle_count,
  hd_ref.hd_income_band_sk AS refunded_income_band,
  hd_ref.hd_vehicle_count AS refunded_vehicle_count,
  COUNT(*) AS num_returns,
  SUM(wr.wr_return_amt) AS total_return_amount,
  AVG(wr.wr_return_amt) AS avg_return_amount,
  SUM(wr.wr_fee) AS total_fee,
  SUM(wr.wr_net_loss) AS total_net_loss,
  SUM(wr.wr_return_amt) / NULLIF(COUNT(*), 0) AS avg_return_per_return,
  SUM(wr.wr_return_amt) / NULLIF(SUM(wr.wr_fee), 0) AS return_to_fee_ratio
FROM web_returns wr
JOIN household_demographics hd_ret
  ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_ref
  ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
WHERE hd_ret.hd_income_band_sk IN (3, 4, 5)
  AND hd_ref.hd_income_band_sk IN (3, 4, 5)
  AND hd_ret.hd_vehicle_count >= 1
  AND hd_ref.hd_vehicle_count >= 1
  AND wr.wr_return_amt > 0
  AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2450500
GROUP BY
  hd_ret.hd_income_band_sk,
  hd_ret.hd_vehicle_count,
  hd_ref.hd_income_band_sk,
  hd_ref.hd_vehicle_count
HAVING COUNT(*) >= 10
ORDER BY total_return_amount DESC
LIMIT 50
