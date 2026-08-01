SELECT cs.cs_order_number,
       cs.cs_net_paid_inc_ship,
       ca.ca_city,
       ca.ca_state
FROM catalog_sales cs
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE cs.cs_coupon_amt > 1000
  AND ca.ca_county = 'Washington County'
LIMIT 100
