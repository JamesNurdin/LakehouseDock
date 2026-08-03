SELECT r.r_reason_id,
       r.r_reason_desc,
       COUNT(*) AS cnt
FROM tpcds.reason r
WHERE r.r_reason_desc LIKE '%price%'
   OR r.r_reason_id = 'AAAAAAAABAAAAAA'
GROUP BY r.r_reason_id, r.r_reason_desc
ORDER BY cnt DESC
LIMIT 10
