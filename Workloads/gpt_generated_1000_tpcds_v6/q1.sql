SELECT
  hd_income_band_sk,
  hd_buy_potential,
  COUNT(*) AS household_cnt
FROM tpcds.household_demographics
WHERE hd_dep_count >= 2
  AND hd_buy_potential <> 'Unknown'
GROUP BY hd_income_band_sk, hd_buy_potential
ORDER BY household_cnt DESC
LIMIT 100
