SELECT
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  COUNT(DISTINCT hd.hd_demo_sk) AS unique_households
FROM tpcds.household_demographics AS hd
JOIN tpcds.income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_dep_count BETWEEN 2 AND 7
  AND ib.ib_upper_bound <= 80000
GROUP BY
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  ib.ib_upper_bound
ORDER BY unique_households DESC
LIMIT 100
