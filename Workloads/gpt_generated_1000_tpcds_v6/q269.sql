SELECT
  hd.hd_demo_sk,
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  hd.hd_vehicle_count
FROM tpcds.household_demographics AS hd
JOIN tpcds.income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_vehicle_count >= 1
  AND ib.ib_lower_bound >= 100000
  AND ib.ib_upper_bound <= 200000
LIMIT 100
