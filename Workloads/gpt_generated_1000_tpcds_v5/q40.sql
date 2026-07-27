WITH joined_data AS (
    SELECT
        s.s_store_name,
        sr.sr_net_loss,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_subdomain,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_full_name
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_store_sk = s.s_store_sk
    WHERE regexp_like(c.c_email_address, '@.*\\.com$')
      AND c.c_first_name LIKE 'A%'
)
SELECT
    s_store_name,
    email_subdomain,
    COUNT(*) AS return_cnt,
    SUM(sr_net_loss) AS total_net_loss,
    MIN(customer_full_name) AS example_customer
FROM joined_data
GROUP BY s_store_name, email_subdomain
ORDER BY total_net_loss DESC
LIMIT 100
