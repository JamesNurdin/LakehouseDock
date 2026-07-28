SELECT
  catalog_returns.cr_returned_date_sk,
  SUM(catalog_returns.cr_return_amount) AS total_return_amount,
  SUM(catalog_returns.cr_net_loss) AS total_net_loss
FROM catalog_returns
WHERE catalog_returns.cr_returning_cdemo_sk IN (1914871, 268615)
  AND catalog_returns.cr_reason_sk = 4
GROUP BY catalog_returns.cr_returned_date_sk
ORDER BY total_return_amount DESC
LIMIT 100
