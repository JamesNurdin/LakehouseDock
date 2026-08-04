SELECT
    ws.ws_order_number,
    ws.ws_ext_list_price,
    ca.ca_city,
    ca.ca_zip
FROM tpcds.web_sales ws
JOIN tpcds.customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE ws.ws_ext_list_price > 5000
  AND ca.ca_city = 'Glendale'
