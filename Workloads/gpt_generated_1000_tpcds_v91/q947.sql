SELECT
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customer_count
FROM tpcds.customer c
JOIN tpcds.customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
WHERE c.c_last_name = 'White'
  AND ca.ca_gmt_offset = -5.00
GROUP BY ca.ca_state
ORDER BY distinct_customer_count DESC
LIMIT 100
