SELECT ca.ca_state,
       COUNT(*) AS return_count,
       SUM(sr.sr_return_amt) AS total_return_amount,
       AVG(sr.sr_return_ship_cost) AS avg_ship_cost
FROM store_returns sr
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE sr.sr_return_ship_cost > 2000
  AND ca.ca_location_type LIKE 'condo%'
GROUP BY ca.ca_state
ORDER BY total_return_amount DESC
LIMIT 100
