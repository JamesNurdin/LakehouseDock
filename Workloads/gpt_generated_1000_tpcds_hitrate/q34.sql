SELECT AVG(ib_upper_bound - ib_lower_bound) AS avg_band_width
FROM tpcds.income_band
WHERE ib_lower_bound >= 40001
  AND ib_upper_bound <= 110000
