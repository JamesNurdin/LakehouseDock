SELECT
  ca_state,
  ca_country,
  COUNT(*) AS address_cnt
FROM tpcds.customer_address
WHERE ca_state IN ('CA', 'TX', 'NY')
  AND ca_country = 'United States'
GROUP BY ca_state, ca_country
ORDER BY address_cnt DESC
LIMIT 10
