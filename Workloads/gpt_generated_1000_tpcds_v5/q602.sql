SELECT
    ws.ws_order_number,
    ws.ws_net_paid,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address
FROM web_sales ws
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE ws.ws_sold_date_sk = 2451422
  AND c.c_email_address LIKE '%@F0NePhPhx1e.edu'
LIMIT 100
