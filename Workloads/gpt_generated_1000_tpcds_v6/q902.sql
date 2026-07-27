SELECT DISTINCT
  ca.ca_city,
  ca.ca_state,
  wr.wr_return_amt,
  wr.wr_return_quantity
FROM web_returns AS wr
JOIN customer_address AS ca
  ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE wr.wr_returning_cdemo_sk = 908769
  AND wr.wr_return_amt > 100
ORDER BY wr.wr_return_amt DESC
LIMIT 100
