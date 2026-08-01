SELECT DISTINCT
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM tpcds.household_demographics AS hd
JOIN tpcds.income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_income_band_sk = 1
  AND hd.hd_dep_count <= 2
  AND ib.ib_upper_bound >= 50000
ORDER BY ib.ib_lower_bound DESC
LIMIT 100
