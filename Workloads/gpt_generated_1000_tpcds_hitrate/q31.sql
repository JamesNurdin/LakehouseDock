SELECT ib_income_band_sk,
       ib_lower_bound,
       ib_upper_bound,
       (ib_upper_bound - ib_lower_bound) AS band_width
FROM tpcds.income_band
WHERE ib_lower_bound >= 100001
  AND ib_upper_bound <= 200000
ORDER BY ib_income_band_sk
