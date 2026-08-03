SELECT
    r.r_reason_desc,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_quantity
FROM catalog_returns cr
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
WHERE cr.cr_return_amount > 500
  AND r.r_reason_id = 'AAAAAAAALAAAAAAA'
GROUP BY r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 10
