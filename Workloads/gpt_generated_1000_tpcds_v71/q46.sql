SELECT
  ib.ib_income_band_sk,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  COUNT(*) AS household_cnt,
  AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt
FROM household_demographics AS hd
JOIN income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_lower_bound >= 10000
  AND hd.hd_vehicle_count >= 0
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY household_cnt DESC
LIMIT 100
