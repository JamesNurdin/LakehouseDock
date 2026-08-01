SELECT COUNT(*) AS band_count,
       MIN(ib_lower_bound) AS min_lower_bound,
       MAX(ib_upper_bound) AS max_upper_bound
FROM tpcds.income_band
WHERE ib_upper_bound BETWEEN 50000 AND 120000
  AND ib_lower_bound > 20000
