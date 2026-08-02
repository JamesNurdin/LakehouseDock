SELECT t_sub_shift, t_hour, COUNT(*) AS num_records
FROM tpcds.time_dim
WHERE t_sub_shift = 'morning'
  AND t_hour BETWEEN 6 AND 12
GROUP BY t_sub_shift, t_hour
ORDER BY num_records DESC, t_hour
