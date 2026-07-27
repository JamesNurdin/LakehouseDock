SELECT
    c.c_first_name,
    c.c_last_name,
    ws.ws_net_paid,
    ws.ws_sold_date_sk
FROM
    web_sales ws
JOIN
    customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE
    ws.ws_sold_date_sk = 2451879
    AND c.c_birth_month = 9
ORDER BY
    ws.ws_net_paid DESC
