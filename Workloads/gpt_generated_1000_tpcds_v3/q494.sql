WITH customer_sales AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_ticket_number AS order_number
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    UNION ALL
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_order_number AS order_number
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2002
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    regexp_extract(c.c_email_address, '@(.*)$') AS email_domain,
    SUM(cs.net_paid) AS total_net_paid,
    COUNT(DISTINCT cs.order_number) AS distinct_orders
FROM customer c
JOIN customer_sales cs ON c.c_customer_sk = cs.customer_sk
WHERE
    regexp_like(c.c_email_address, '@example\\.com$')
    AND regexp_like(c.c_first_name, '^[A-M]')
    AND (c.c_first_name || ' ' || c.c_last_name) LIKE '%son%'
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    regexp_extract(c.c_email_address, '@(.*)$')
HAVING
    SUM(cs.net_paid) > (
        SELECT AVG(total_per_customer) FROM (
            SELECT customer_sk, SUM(net_paid) AS total_per_customer
            FROM customer_sales
            GROUP BY customer_sk
        ) avg_sub
    )
ORDER BY total_net_paid DESC
LIMIT 100
