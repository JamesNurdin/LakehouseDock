SELECT DISTINCT cr.cr_returning_addr_sk, r.r_reason_desc
FROM catalog_returns cr
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE cr.cr_returning_addr_sk = 352647
  AND cr.cr_reversed_charge > 20.0
ORDER BY r.r_reason_desc
LIMIT 100
