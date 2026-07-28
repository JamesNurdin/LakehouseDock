WITH recent_customers AS (
    SELECT DISTINCT ws.ws_bill_customer_sk AS cust_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    d.d_year,
    concat('Customer ', c.c_customer_id) AS cust_label,
    regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
    sum(ws.ws_net_paid) AS total_net_paid
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE
    c.c_first_name LIKE 'A%'
    AND regexp_like(c.c_email_address, '@.*\\.org$')
    AND wsite.web_street_name LIKE '%Washington%'
    AND c.c_customer_sk IN (SELECT cust_sk FROM recent_customers)
GROUP BY
    d.d_year,
    c.c_customer_id,
    regexp_extract(c.c_email_address, '@([^.]*)\\.', 1)
ORDER BY total_net_paid DESC
LIMIT 20
