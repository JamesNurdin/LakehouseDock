SELECT DISTINCT hd.hd_buy_potential,
       ib.ib_lower_bound
FROM tpcds.household_demographics AS hd
JOIN tpcds.income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_vehicle_count >= 0
  AND ib.ib_upper_bound <= 100000
ORDER BY hd.hd_buy_potential
