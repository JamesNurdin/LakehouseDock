SELECT ca.ca_city,
       ca.ca_state,
       sum(wr.wr_return_amt) AS total_return_amount,
       count(*) AS return_count
FROM web_returns wr
JOIN customer_address ca
  ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE ca.ca_gmt_offset = -8.00
  AND ca.ca_location_type = 'single family'
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_return_amount DESC
LIMIT 100
