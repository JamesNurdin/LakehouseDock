SELECT
  ib_income_band_sk,
  ib_lower_bound,
  ib_upper_bound,
  (ib_upper_bound - ib_lower_bound) AS band_width
FROM tpcds.income_band
WHERE ib_upper_bound BETWEEN 70000 AND 150000
  AND ib_lower_bound >= 50001
ORDER BY ib_income_band_sk
