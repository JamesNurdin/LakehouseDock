SELECT ca.ca_city,
       SUM(wr.wr_return_amt) AS total_return_amount
FROM web_returns wr
JOIN customer_address ca
  ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE ca.ca_country = 'United States'
  AND wr.wr_return_quantity > 10
GROUP BY ca.ca_city
ORDER BY total_return_amount DESC
LIMIT 10
