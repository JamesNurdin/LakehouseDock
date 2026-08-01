SELECT DISTINCT ib_income_band_sk,
                ib_lower_bound,
                ib_upper_bound
FROM   income_band
WHERE  ib_lower_bound >= 110000
  AND  ib_upper_bound <= 200000
LIMIT 100
