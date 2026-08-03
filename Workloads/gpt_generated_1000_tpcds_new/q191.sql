SELECT
  hd.hd_income_band_sk,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  COUNT(*) AS demo_cnt
FROM tpcds.household_demographics AS hd
JOIN tpcds.income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_buy_potential = '>10000'
  AND hd.hd_dep_count >= 5
  AND ib.ib_upper_bound <= 200000
GROUP BY hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY demo_cnt DESC
LIMIT 10
