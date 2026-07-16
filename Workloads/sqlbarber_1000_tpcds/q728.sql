SELECT hd.hd_demo_sk,
       hd.hd_buy_potential,
       CASE
           WHEN ib.ib_upper_bound > 80000 THEN 'High'
           WHEN ib.ib_lower_bound < 140001 THEN 'Low'
           ELSE 'Medium'
       END AS income_category,
       (hd.hd_vehicle_count * hd.hd_dep_count) AS vehicle_dep_product,
       ib.ib_lower_bound + ib.ib_upper_bound AS income_band_midpoint
FROM household_demographics AS hd
JOIN income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_dep_count > 3
