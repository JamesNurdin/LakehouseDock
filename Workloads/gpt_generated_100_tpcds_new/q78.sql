SELECT
  ca.ca_state,
  ca.ca_city,
  SUM(wr.wr_return_amt) AS total_return_amount,
  COUNT(*) AS return_count
FROM web_returns AS wr
JOIN customer_address AS ca
  ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE ca.ca_gmt_offset = -5.00
  AND wr.wr_return_amt > 150.00
GROUP BY ca.ca_state, ca.ca_city
ORDER BY total_return_amount DESC
LIMIT 10
