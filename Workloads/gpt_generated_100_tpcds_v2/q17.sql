SELECT r.r_reason_desc,
       COUNT(*) AS return_count
FROM tpcds.catalog_returns AS cr
JOIN tpcds.reason AS r
  ON cr.cr_reason_sk = r.r_reason_sk
WHERE cr.cr_return_amount > 100
GROUP BY r.r_reason_desc
ORDER BY return_count DESC
LIMIT 10
