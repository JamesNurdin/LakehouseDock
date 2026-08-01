SELECT
  r_reason_id,
  r_reason_desc
FROM tpcds.reason
WHERE r_reason_desc LIKE '%damaged%'
  AND r_reason_id = 'AAAAAAAABBAAAAAA'
ORDER BY r_reason_sk DESC
LIMIT 100
