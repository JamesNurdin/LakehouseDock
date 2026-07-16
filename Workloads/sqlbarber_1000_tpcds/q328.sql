SELECT ca_state, SUM(cs_net_paid) AS total_net_paid
FROM catalog_sales
INNER JOIN customer_address ON catalog_sales.cs_bill_addr_sk = customer_address.ca_address_sk
WHERE ca_state = 'WV' AND cs_sold_date_sk = 2450856
GROUP BY ca_state
