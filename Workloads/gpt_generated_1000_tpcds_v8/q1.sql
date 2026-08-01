SELECT
  catalog_returns.cr_reason_sk,
  SUM(catalog_returns.cr_return_amount) AS total_return_amount,
  COUNT(*) AS return_cnt
FROM catalog_returns
WHERE catalog_returns.cr_reason_sk IN (12, 24)
  AND catalog_returns.cr_ship_mode_sk = 6
GROUP BY catalog_returns.cr_reason_sk
ORDER BY total_return_amount DESC
LIMIT 100
