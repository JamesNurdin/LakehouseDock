SELECT DISTINCT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       ws.ws_order_number,
       ws.ws_ext_sales_price,
       ws.ws_ext_tax
FROM tpcds.customer AS c
JOIN tpcds.web_sales AS ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE c.c_salutation = 'Mr.'
  AND ws.ws_ext_list_price > 5000
LIMIT 100
