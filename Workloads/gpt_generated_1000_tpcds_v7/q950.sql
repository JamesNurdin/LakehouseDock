WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        ca_cur.ca_city,
        regexp_extract(c.c_email_address, '@([^.]*)\\.com', 1) AS email_domain,
        CONCAT(regexp_extract(c.c_email_address, '@([^.]*)\\.com', 1), '_', ca_cur.ca_city) AS domain_city
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca_cur
        ON c.c_current_addr_sk = ca_cur.ca_address_sk
    WHERE regexp_like(c.c_email_address, '@example\\.com$')
      AND ca_cur.ca_city LIKE 'A%'
)
SELECT
    fc.c_customer_sk,
    fc.email_domain,
    fc.ca_city,
    fc.domain_city,
    COUNT(sr.sr_ticket_number) AS returns_cnt,
    SUM(sr.sr_net_loss) AS total_net_loss
FROM filtered_customers fc
JOIN tpcds.store_returns sr
    ON sr.sr_customer_sk = fc.c_customer_sk
JOIN tpcds.customer_address ca_ret
    ON sr.sr_addr_sk = ca_ret.ca_address_sk
GROUP BY
    fc.c_customer_sk,
    fc.email_domain,
    fc.ca_city,
    fc.domain_city
ORDER BY total_net_loss DESC
LIMIT 10
