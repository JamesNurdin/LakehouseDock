SELECT ca.ca_state,
       ca.ca_city,
       COUNT(DISTINCT s.ss_customer_sk) AS distinct_customers
FROM store_sales s
JOIN customer_address ca
  ON s.ss_addr_sk = ca.ca_address_sk
WHERE ca.ca_gmt_offset = -5.00
  AND s.ss_ext_sales_price > 1000
GROUP BY ca.ca_state, ca.ca_city
ORDER BY distinct_customers DESC
LIMIT 100
