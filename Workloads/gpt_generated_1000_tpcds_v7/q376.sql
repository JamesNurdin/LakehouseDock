SELECT r_reason_id,
       r_reason_desc
FROM   reason
WHERE  r_reason_desc LIKE '%product%'
  AND  r_reason_id = 'AAAAAAAALAAAAAAA'
LIMIT 100
