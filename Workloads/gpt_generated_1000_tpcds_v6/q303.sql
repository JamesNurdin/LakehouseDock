SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  ca.ca_city,
  ca.ca_state
FROM tpcds.customer AS c
JOIN tpcds.customer_address AS ca
  ON c.c_current_addr_sk = ca.ca_address_sk
WHERE c.c_birth_month = 7
  AND ca.ca_location_type = 'apartment'
ORDER BY c.c_customer_id
