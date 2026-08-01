SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(hd.hd_demo_sk) AS demo_cnt,
    AVG(hd.hd_vehicle_count) AS avg_vehicles
FROM tpcds.household_demographics AS hd
JOIN tpcds.income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_lower_bound >= 30000
  AND hd.hd_buy_potential = '501-1000'
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY ib.ib_lower_bound
