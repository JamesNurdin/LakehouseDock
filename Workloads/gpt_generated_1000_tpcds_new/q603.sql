SELECT t_time_id,
       t_hour,
       t_shift,
       COUNT(*) AS cnt
FROM tpcds.time_dim
WHERE t_time_id = 'AAAAAAAAPAAAAAAA'
  AND t_hour BETWEEN 8 AND 17
GROUP BY t_time_id, t_hour, t_shift
ORDER BY cnt DESC
LIMIT 10
