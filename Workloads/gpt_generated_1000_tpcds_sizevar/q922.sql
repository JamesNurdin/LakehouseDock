SELECT ca.ca_state,
       COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
       SUM(sr.sr_refunded_cash) AS total_refunded
FROM store_returns sr
JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
WHERE sr.sr_return_amt_inc_tax > 1000
  AND ca.ca_street_type = 'Blvd'
GROUP BY ca.ca_state
ORDER BY total_refunded DESC
LIMIT 10
