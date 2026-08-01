SELECT
  hd_income_band_sk,
  COUNT(*) AS household_count,
  AVG(hd_vehicle_count) AS avg_vehicle_count
FROM tpcds.household_demographics
WHERE hd_dep_count > 2
  AND hd_income_band_sk IN (6, 8)
GROUP BY hd_income_band_sk
ORDER BY household_count DESC
LIMIT 100
