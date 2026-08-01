SELECT
  s.s_store_id,
  s.s_store_name,
  concat(s.s_city, ', ', s.s_state) AS location,
  regexp_extract(s.s_suite_number, '(\\d+)', 1) AS suite_num,
  SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
WHERE s.s_county LIKE '%County'
  AND regexp_like(s.s_suite_number, '^Suite \\d+ [A-Z]?$')
  AND d.d_year = 2002
  AND t.t_shift = 'first'
GROUP BY
  s.s_store_id,
  s.s_store_name,
  concat(s.s_city, ', ', s.s_state),
  regexp_extract(s.s_suite_number, '(\\d+)', 1)
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
