SELECT ib.ib_lower_bound,
       ib.ib_upper_bound,
       COUNT(*) AS household_count
FROM tpcds.household_demographics hd
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_dep_count >= 5
  AND ib.ib_lower_bound >= 120000
GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
HAVING COUNT(*) > 1
ORDER BY household_count DESC
