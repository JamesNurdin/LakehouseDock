SELECT
  s.s_store_name,
  s.s_city,
  s.s_manager,
  s.s_gmt_offset,
  d.d_year,
  CONCAT(s.s_store_name, ' - ', s.s_city) AS store_location,
  substr(s.s_manager, 1, 3) AS mgr_initials,
  regexp_extract(s.s_zip, '(\\d+)', 1) AS zip_digits,
  CASE
    WHEN s.s_gmt_offset <= -6 THEN 'West'
    WHEN s.s_gmt_offset > -6 AND s.s_gmt_offset <= -3 THEN 'Central'
    ELSE 'East'
  END AS region,
  COUNT(*) AS return_count,
  SUM(sr.sr_net_loss) AS total_net_loss,
  CASE
    WHEN SUM(sr.sr_net_loss) > 5000 THEN 'High'
    WHEN SUM(sr.sr_net_loss) > 1000 THEN 'Medium'
    ELSE 'Low'
  END AS loss_category
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2021
  AND regexp_like(r.r_reason_desc, '^Damaged.*')
  AND s.s_store_name LIKE '%store%'
GROUP BY
  s.s_store_name,
  s.s_city,
  s.s_manager,
  s.s_gmt_offset,
  d.d_year,
  CONCAT(s.s_store_name, ' - ', s.s_city),
  substr(s.s_manager, 1, 3),
  regexp_extract(s.s_zip, '(\\d+)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
