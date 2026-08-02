SELECT ca.ca_city,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_count
FROM catalog_returns AS cr
JOIN customer_address AS ca
  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
WHERE cr.cr_fee > 70
  AND ca.ca_country = 'United States'
GROUP BY ca.ca_city
ORDER BY total_return_amount DESC
LIMIT 100
