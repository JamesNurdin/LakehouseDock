SELECT ca.ca_city,
       ca.ca_state,
       COUNT(*) AS sales_count,
       SUM(ss.ss_net_paid) AS total_net_paid,
       AVG(ss.ss_list_price) AS avg_list_price
FROM store_sales ss
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE ca.ca_city = 'Wilson'
  AND ss.ss_list_price > 100
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_net_paid DESC
LIMIT 100
