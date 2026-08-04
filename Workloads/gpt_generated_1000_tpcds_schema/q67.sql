SELECT ca.ca_city,
       ca.ca_state,
       COUNT(DISTINCT cs.cs_order_number) AS orders,
       SUM(cs.cs_net_paid_inc_ship) AS total_net_paid
FROM catalog_sales cs
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE cs.cs_ship_cdemo_sk = 599432
  AND cs.cs_net_paid_inc_ship > 3000
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_net_paid DESC
LIMIT 10
