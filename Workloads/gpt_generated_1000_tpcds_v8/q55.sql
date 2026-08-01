SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    (ib_upper_bound - ib_lower_bound) AS band_width
FROM tpcds.income_band
WHERE ib_lower_bound >= 50000
  AND ib_upper_bound <= 150000
ORDER BY band_width DESC, ib_income_band_sk ASC
LIMIT 100
