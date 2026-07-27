WITH billed AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_net_profit,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ca.ca_city,
        ca.ca_street_name,
        ca.ca_suite_number,
        ca.ca_zip,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        CASE
            WHEN regexp_like(ca.ca_street_name, '^Oak') THEN 'StartsWithOak'
            WHEN regexp_like(ca.ca_street_name, 'Oak$') THEN 'EndsWithOak'
            ELSE 'Other'
        END AS oak_category
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city LIKE 'San %'
      AND regexp_like(ca.ca_street_name, 'Oak')
)
SELECT
    oak_category,
    email_domain,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    SUM(ws_net_paid) AS total_paid,
    SUM(ws_net_profit) AS total_profit,
    CASE
        WHEN SUM(ws_net_profit) > 0 THEN 'Profitable'
        ELSE 'NotProfitable'
    END AS profit_flag
FROM billed
GROUP BY oak_category, email_domain
HAVING COUNT(DISTINCT ws_order_number) > 5
ORDER BY total_paid DESC
LIMIT 100
