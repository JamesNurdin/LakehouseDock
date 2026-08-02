SELECT
  r.r_reason_desc,
  COUNT(*) AS reason_count
FROM tpcds.reason AS r
WHERE r.r_reason_id IN ('AAAAAAAAMAAAAAAA', 'AAAAAAAADAAAAAAA')
GROUP BY r.r_reason_desc
ORDER BY reason_count DESC
LIMIT 10
