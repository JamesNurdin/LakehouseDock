SELECT r_reason_id, r_reason_desc
FROM tpcds.reason
WHERE r_reason_id IN ('AAAAAAAAGAAAAAAA', 'AAAAAAAACBAAAAAA')
  AND r_reason_sk > 10
ORDER BY r_reason_id
LIMIT 100
