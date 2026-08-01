SELECT d_year,
       COUNT(DISTINCT d_date) AS distinct_date_cnt
FROM tpcds.date_dim
WHERE d_current_day = 'N'
  AND d_first_dom > 2415000
GROUP BY d_year
ORDER BY distinct_date_cnt DESC
LIMIT 100
