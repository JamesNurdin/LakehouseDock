SELECT
  sr_store_sk,
  SUM(sr_return_amt) AS total_return_amt,
  AVG(sr_net_loss) AS avg_net_loss,
  COUNT(*) AS return_cnt
FROM tpcds.store_returns
WHERE sr_return_amt > 100.00
  AND sr_net_loss > 500.00
GROUP BY sr_store_sk
ORDER BY total_return_amt DESC
LIMIT 10
