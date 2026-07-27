SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_paid) AS total_paid
FROM
    web_sales ws
JOIN
    customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE
    ws.ws_list_price > 100.00
    AND c.c_birth_year = 1948
    AND ws.ws_ship_addr_sk = 2587113
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name
ORDER BY
    total_paid DESC
LIMIT 100
