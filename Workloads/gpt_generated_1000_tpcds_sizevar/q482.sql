SELECT hd_buy_potential,
       COUNT(DISTINCT hd_demo_sk) AS household_cnt
FROM tpcds.household_demographics
WHERE hd_dep_count >= 3
  AND hd_vehicle_count >= 0
GROUP BY hd_buy_potential
ORDER BY household_cnt DESC
