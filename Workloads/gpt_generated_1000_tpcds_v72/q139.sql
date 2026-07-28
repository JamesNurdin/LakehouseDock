SELECT ib_income_band_sk,
       ib_lower_bound,
       ib_upper_bound
FROM tpcds.income_band
WHERE ib_upper_bound BETWEEN 60000 AND 110000
  AND ib_lower_bound >= 60001
ORDER BY ib_income_band_sk
