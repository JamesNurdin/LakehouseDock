SELECT DISTINCT ib_income_band_sk,
       ib_lower_bound,
       ib_upper_bound
FROM tpcds.income_band
WHERE ib_lower_bound >= 150000
  AND ib_upper_bound <= 180000
ORDER BY ib_income_band_sk
