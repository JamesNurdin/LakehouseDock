SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(*) AS household_cnt
FROM tpcds.household_demographics hd
JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_vehicle_count >= 2
  AND hd.hd_buy_potential = '5001-10000'
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY household_cnt DESC
LIMIT 100
