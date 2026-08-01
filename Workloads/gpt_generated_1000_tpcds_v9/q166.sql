SELECT
  ca.ca_state,
  ca.ca_city,
  ca.ca_suite_number,
  ca.ca_street_type,
  SUM(sr.sr_return_amt) AS total_return_amount,
  AVG(sr.sr_return_tax) AS avg_return_tax,
  COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
  MIN(sr.sr_return_amt) AS min_return_amount,
  MAX(sr.sr_return_amt) AS max_return_amount,
  (
    SELECT SUM(sr2.sr_return_amt)
    FROM store_returns sr2
    JOIN customer_address ca2 ON sr2.sr_addr_sk = ca2.ca_address_sk
    WHERE ca2.ca_state = ca.ca_state
  ) AS state_total_return_amount
FROM store_returns sr
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'CA'
  AND ca.ca_city = 'San Jose'
  AND ca.ca_suite_number IN ('Suite A', 'Suite 280')
  AND ca.ca_street_type = 'Lane'
  AND sr.sr_return_tax > 5.00
  AND sr.sr_refunded_cash BETWEEN 50 AND 600
  AND sr.sr_return_amt > 10.00
GROUP BY ca.ca_state, ca.ca_city, ca.ca_suite_number, ca.ca_street_type
ORDER BY total_return_amount DESC
LIMIT 100
