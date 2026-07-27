SELECT
    hd_buy_potential,
    COUNT(DISTINCT hd_demo_sk) AS demo_cnt,
    AVG(hd_vehicle_count) AS avg_vehicles
FROM tpcds.household_demographics
WHERE hd_dep_count BETWEEN 1 AND 5
  AND hd_income_band_sk IN (2, 4, 6)
GROUP BY hd_buy_potential
ORDER BY demo_cnt DESC
LIMIT 100
