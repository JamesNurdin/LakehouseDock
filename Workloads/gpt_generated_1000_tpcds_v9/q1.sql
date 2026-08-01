SELECT
    r_reason_desc,
    COUNT(*) AS reason_count
FROM tpcds.reason
WHERE r_reason_desc LIKE '%missing%'
  AND r_reason_sk > 5
GROUP BY r_reason_desc
ORDER BY reason_count DESC
LIMIT 100
