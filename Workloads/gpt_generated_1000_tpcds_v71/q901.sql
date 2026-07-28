SELECT
  ca.ca_city,
  ca.ca_state,
  SUM(ss.ss_net_paid) AS total_net_paid
FROM store_sales ss
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE ss.ss_ext_list_price > 6000
  AND ss.ss_promo_sk IN (106, 236)
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_net_paid DESC
LIMIT 100
