SELECT DISTINCT
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  ib.ib_upper_bound
FROM tpcds.household_demographics AS hd
JOIN tpcds.income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_dep_count BETWEEN 1 AND 5
  AND ib.ib_lower_bound >= 20000
ORDER BY hd.hd_buy_potential ASC, ib.ib_lower_bound ASC
