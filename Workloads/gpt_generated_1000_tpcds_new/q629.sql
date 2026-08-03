SELECT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    ca.ca_city,
    ca.ca_state
FROM catalog_sales AS cs
JOIN customer_address AS ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE cs.cs_list_price > 150.00
  AND ca.ca_state = 'CA'
LIMIT 100
