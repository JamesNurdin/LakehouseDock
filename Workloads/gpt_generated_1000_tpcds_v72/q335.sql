SELECT
  t_hour,
  t_shift,
  COUNT(*) AS record_count
FROM tpcds.time_dim
WHERE t_shift = 'first'
  AND t_hour BETWEEN 8 AND 12
GROUP BY t_hour, t_shift
ORDER BY t_hour
