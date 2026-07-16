SELECT ca_state, ca_city, SUM(cs_net_paid) AS total_catalog_net_paid, SUM(ss_net_paid) AS total_store_net_paid
FROM catalog_sales
JOIN customer_address ON catalog_sales.cs_bill_addr_sk = customer_address.ca_address_sk
JOIN store_sales ON store_sales.ss_addr_sk = customer_address.ca_address_sk
WHERE ca_country = 'United States' AND cs_sold_date_sk BETWEEN 2450842 AND 2450839
GROUP BY ca_state, ca_city
