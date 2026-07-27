SELECT d.d_week_seq,
       COUNT(*) AS closed_store_cnt
FROM   store s
JOIN   date_dim d
       ON s.s_closed_date_sk = d.d_date_sk
WHERE  d.d_week_seq = 12
  AND  s.s_manager = 'Scott Smith'
GROUP BY d.d_week_seq
LIMIT 100
