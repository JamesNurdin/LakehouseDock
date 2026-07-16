SELECT hd.hd_demo_sk,
       hd.hd_buy_potential,
       CASE WHEN ib.ib_upper_bound > 150000 THEN 'High' ELSE 'Low' END AS income_category,
       hd.hd_vehicle_count * 2 AS double_vehicle_count,
       hd.hd_dep_count + hd.hd_vehicle_count AS total_dep_vehicle,
       CASE WHEN hd.hd_buy_potential = '500+' THEN 'Premium' ELSE 'Standard' END AS buy_potential_category,
       ib.ib_lower_bound + ib.ib_upper_bound AS band_sum,
       CONCAT(CAST(ib.ib_lower_bound AS VARCHAR), '-', CAST(ib.ib_upper_bound AS VARCHAR)) AS band_range
FROM household_demographics hd
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_dep_count > 0
