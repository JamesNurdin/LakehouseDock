SELECT ib_lower_bound,
       COUNT(*) AS band_cnt
FROM tpcds.income_band
WHERE ib_upper_bound >= 40000
  AND ib_lower_bound <= 100001
GROUP BY ib_lower_bound
HAVING COUNT(*) > 1
ORDER BY band_cnt DESC
