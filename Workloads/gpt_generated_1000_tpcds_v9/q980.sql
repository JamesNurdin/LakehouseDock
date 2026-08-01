SELECT avg(ib_upper_bound - ib_lower_bound) AS avg_band_width
FROM tpcds.income_band
WHERE ib_lower_bound >= 80000
  AND ib_upper_bound <= 200000
