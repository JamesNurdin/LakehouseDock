SELECT ca_state, COUNT(*) AS address_count
FROM tpcds.customer_address
WHERE ca_location_type = 'apartment'
  AND ca_zip = '39145'
GROUP BY ca_state
ORDER BY address_count DESC
LIMIT 100
