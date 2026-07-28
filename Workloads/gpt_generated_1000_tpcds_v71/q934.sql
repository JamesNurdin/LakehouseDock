SELECT DISTINCT
    hd.hd_demo_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_vehicle_count
FROM tpcds.household_demographics AS hd
JOIN tpcds.income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_upper_bound > 90000
  AND hd.hd_vehicle_count >= 2
LIMIT 100
