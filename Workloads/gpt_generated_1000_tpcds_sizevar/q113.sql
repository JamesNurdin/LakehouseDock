SELECT
  wr_refunded_customer_sk,
  wr_reason_sk,
  SUM(wr_return_amt) AS total_return_amt,
  COUNT(*) AS returns_count
FROM tpcds.web_returns
WHERE wr_refunded_customer_sk = 10283268
  AND wr_reason_sk = 46
GROUP BY wr_refunded_customer_sk, wr_reason_sk
ORDER BY total_return_amt DESC
