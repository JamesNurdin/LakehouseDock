SELECT hd.hd_demo_sk,
       hd.hd_buy_potential,
       ib.ib_lower_bound,
       ib.ib_upper_bound
FROM tpcds.household_demographics AS hd
JOIN tpcds.income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_dep_count >= 5
  AND ib.ib_lower_bound >= 90000
ORDER BY ib.ib_upper_bound DESC
LIMIT 100
