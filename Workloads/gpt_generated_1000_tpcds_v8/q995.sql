SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(hd.hd_demo_sk) AS household_count,
    AVG(hd.hd_dep_count) AS avg_dep_count
FROM tpcds.household_demographics AS hd
JOIN tpcds.income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_buy_potential = '501-1000'
  AND ib.ib_lower_bound >= 70001
  AND ib.ib_upper_bound <= 180000
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY ib.ib_lower_bound ASC
LIMIT 100
