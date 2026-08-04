SELECT r.r_reason_desc,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_cnt,
       AVG(cr.cr_fee) AS avg_fee
FROM catalog_returns cr
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
WHERE r.r_reason_id = 'AAAAAAAABAAAAAAA'
  AND cr.cr_fee > 50
GROUP BY r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 10
