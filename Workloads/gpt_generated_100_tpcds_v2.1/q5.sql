SELECT ca.ca_state,
       SUM(ss.ss_net_paid) AS total_net_paid
FROM store_sales ss
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'CA'
  AND ss.ss_store_sk = 772
GROUP BY ca.ca_state
ORDER BY total_net_paid DESC
LIMIT 100
