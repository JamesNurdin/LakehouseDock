SELECT DISTINCT ca.ca_city,
                ca.ca_state,
                ws.ws_net_paid_inc_tax
FROM tpcds.web_sales ws
JOIN tpcds.customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE ca.ca_location_type = 'condo'
  AND ws.ws_net_paid_inc_tax > 2000.00
LIMIT 100
