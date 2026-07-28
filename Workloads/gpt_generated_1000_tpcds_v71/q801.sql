SELECT
    r_reason_id,
    r_reason_desc
FROM tpcds.reason
WHERE r_reason_id = 'AAAAAAAABBAAAAAA'
  AND r_reason_desc LIKE '%color%'
ORDER BY r_reason_id
LIMIT 100
