SELECT ib_income_band_sk,
       ib_lower_bound,
       ib_upper_bound,
       (ib_upper_bound - ib_lower_bound) AS band_width
FROM tpcds.income_band
WHERE ib_lower_bound >= 20001
  AND ib_upper_bound <= 130000
ORDER BY ib_lower_bound ASC
