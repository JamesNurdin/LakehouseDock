SELECT
    hd_income_band_sk,
    hd_buy_potential,
    COUNT(DISTINCT hd_demo_sk) AS household_cnt
FROM tpcds.household_demographics
WHERE hd_vehicle_count >= 1
  AND hd_income_band_sk IN (5, 12)
GROUP BY hd_income_band_sk, hd_buy_potential
ORDER BY household_cnt DESC
LIMIT 100
