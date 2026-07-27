SELECT hd_buy_potential,
       COUNT(*) AS household_cnt,
       AVG(hd_vehicle_count) AS avg_vehicles
FROM tpcds.household_demographics
WHERE hd_vehicle_count >= 1
  AND hd_dep_count <= 5
GROUP BY hd_buy_potential
ORDER BY household_cnt DESC
LIMIT 100
