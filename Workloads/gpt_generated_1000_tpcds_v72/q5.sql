SELECT
  ca.ca_city,
  ca.ca_state,
  wr.wr_return_amt,
  wr.wr_net_loss
FROM tpcds.web_returns AS wr
JOIN tpcds.customer_address AS ca
  ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE ca.ca_city = 'Valley View'
  AND wr.wr_return_amt > 100
ORDER BY wr.wr_return_amt DESC
LIMIT 100
