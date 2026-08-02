SELECT ib.ib_income_band_sk,
       COUNT(*) AS household_cnt,
       AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt
FROM household_demographics AS hd
JOIN income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_vehicle_count >= 1
  AND ib.ib_upper_bound <= 130000
GROUP BY ib.ib_income_band_sk
ORDER BY household_cnt DESC
LIMIT 100
