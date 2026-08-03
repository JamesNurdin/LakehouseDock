SELECT
  ca.ca_city,
  ca.ca_state,
  COUNT(*) AS num_returns,
  SUM(wr.wr_return_amt) AS total_return_amount,
  SUM(wr.wr_return_quantity) AS total_quantity
FROM web_returns wr
JOIN customer_address ca
  ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE wr.wr_refunded_customer_sk = 11462543
  AND wr.wr_return_amt > 100.00
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_return_amount DESC
LIMIT 10
