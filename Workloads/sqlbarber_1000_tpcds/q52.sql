SELECT hd.hd_demo_sk,
       hd.hd_buy_potential,
       (hd.hd_vehicle_count * 2) AS double_vehicle_count,
       (hd.hd_dep_count + hd.hd_vehicle_count) AS total_dep_and_vehicle,
       CASE WHEN ib.ib_upper_bound > ib.ib_lower_bound THEN 'UpperGreater' ELSE 'UpperNotGreater' END AS band_relation,
       CASE WHEN hd.hd_buy_potential = '5001-10000     ' THEN 1 WHEN hd.hd_buy_potential = 'Unknown        ' THEN 0 ELSE -1 END AS buy_potential_score
FROM household_demographics hd
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_lower_bound > 30001 AND ib.ib_upper_bound < 10000
