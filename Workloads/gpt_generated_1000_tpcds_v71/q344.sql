SELECT
  reason.r_reason_desc,
  SUM(catalog_returns.cr_return_amount) AS total_return_amount,
  SUM(catalog_returns.cr_refunded_cash) AS total_refunded_cash
FROM catalog_returns
JOIN reason ON catalog_returns.cr_reason_sk = reason.r_reason_sk
WHERE catalog_returns.cr_refunded_customer_sk IN (9240699, 11253159)
  AND catalog_returns.cr_return_amount > 100.0
GROUP BY reason.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
