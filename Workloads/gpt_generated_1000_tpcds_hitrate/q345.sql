SELECT
  hd.hd_vehicle_count,
  COUNT(*) AS household_cnt,
  AVG(hd.hd_dep_count) AS avg_dep_count
FROM household_demographics AS hd
JOIN income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_lower_bound > 50000
  AND hd.hd_buy_potential = '1001-5000'
GROUP BY hd.hd_vehicle_count
ORDER BY household_cnt DESC
