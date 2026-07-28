SELECT
  cs.cs_order_number,
  cs.cs_list_price,
  cs.cs_net_paid_inc_ship_tax,
  ca.ca_city,
  ca.ca_state
FROM tpcds.catalog_sales AS cs
JOIN tpcds.customer_address AS ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE cs.cs_list_price > 90
  AND cs.cs_net_paid_inc_ship_tax > 2000
  AND ca.ca_country = 'United States'
LIMIT 100
