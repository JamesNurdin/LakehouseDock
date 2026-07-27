SELECT DISTINCT
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM tpcds.household_demographics AS hd
JOIN tpcds.income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_dep_count >= 3
  AND ib.ib_lower_bound >= 110001
ORDER BY ib.ib_lower_bound DESC
