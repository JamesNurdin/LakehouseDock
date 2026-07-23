SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_paid) AS total_net_paid
FROM
    tpcds.customer AS c
INNER JOIN
    tpcds.web_sales AS ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE
    c.c_first_name = 'Javier'
    AND ws.ws_ext_wholesale_cost > 2000
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name
ORDER BY
    total_net_paid DESC
LIMIT 100
