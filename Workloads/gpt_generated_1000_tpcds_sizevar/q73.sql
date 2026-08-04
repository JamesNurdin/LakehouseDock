SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(hd.hd_demo_sk) AS household_cnt,
    AVG(hd.hd_vehicle_count) AS avg_vehicles
FROM tpcds.household_demographics AS hd
JOIN tpcds.income_band AS ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_dep_count >= 5
  AND ib.ib_lower_bound >= 80000
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY household_cnt DESC
LIMIT 10
