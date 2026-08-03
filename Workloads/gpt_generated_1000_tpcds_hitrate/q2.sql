SELECT
  sr_returned_date_sk,
  SUM(sr_return_amt) AS total_return_amt,
  AVG(sr_return_tax) AS avg_return_tax
FROM tpcds.store_returns
WHERE sr_returned_date_sk BETWEEN 2451000 AND 2452000
  AND sr_return_amt > 100.00
GROUP BY sr_returned_date_sk
ORDER BY sr_returned_date_sk
