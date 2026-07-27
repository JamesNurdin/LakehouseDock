SELECT DISTINCT r_reason_id,
                r_reason_desc
FROM   reason
WHERE  r_reason_id = 'AAAAAAAABAAAAAAA'
   OR  r_reason_desc LIKE '%price%'
ORDER BY r_reason_id
