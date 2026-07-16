SELECT hd.hd_demo_sk,
       hd.hd_buy_potential,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       CASE WHEN hd.hd_vehicle_count = 0 THEN 'NoVehicle'
            WHEN hd.hd_vehicle_count = 1 THEN 'OneVehicle'
            ELSE 'MultipleVehicles' END AS vehicle_category,
       (ib.ib_upper_bound - ib.ib_lower_bound) AS income_range_width,
       (hd.hd_dep_count * 2 + hd.hd_vehicle_count) AS dep_vehicle_score,
       CASE WHEN ib.ib_upper_bound > 110000 THEN 'HighIncome' ELSE 'LowIncome' END AS income_category
FROM household_demographics hd
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_dep_count > 9
  AND ib.ib_lower_bound < 30001
