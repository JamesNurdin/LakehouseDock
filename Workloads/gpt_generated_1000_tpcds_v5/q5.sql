SELECT DISTINCT r_reason_desc
FROM tpcds.reason
WHERE r_reason_sk IN (8, 15)
  AND r_reason_id = 'AAAAAAAACBAAAAAA'
LIMIT 100
