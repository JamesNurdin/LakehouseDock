SELECT ca_city,
       ca_state,
       COUNT(*) AS address_count
FROM tpcds.customer_address
WHERE ca_county = 'Washington County'
  AND ca_street_type = 'Ave'
GROUP BY ca_city, ca_state
ORDER BY address_count DESC
