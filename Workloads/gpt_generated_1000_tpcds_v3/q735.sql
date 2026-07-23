SELECT r_reason_desc,
       COUNT(DISTINCT r_reason_id) AS distinct_reason_ids
FROM tpcds.reason
WHERE r_reason_desc = 'Wrong size'
   OR r_reason_desc LIKE '%warranty%'
GROUP BY r_reason_desc
ORDER BY distinct_reason_ids DESC
LIMIT 100
