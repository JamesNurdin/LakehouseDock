SELECT ca_state,
       COUNT(DISTINCT ca_address_id) AS num_addresses
FROM tpcds.customer_address
WHERE ca_street_name = 'Williams Sixth'
  AND ca_street_number = '76'
GROUP BY ca_state
ORDER BY num_addresses DESC
