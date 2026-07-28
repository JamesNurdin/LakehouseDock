WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_addr_sk,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        c.c_email_address
    FROM tpcds.store_sales ss
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    WHERE
        c.c_first_name LIKE 'A%'
        AND regexp_like(c.c_email_address, '\\d+@.+\\.com')
)
SELECT
    s.s_store_name,
    ca.ca_city,
    regexp_extract(f.c_email_address, '@(.+)$', 1) AS email_domain,
    SUM(f.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT f.ss_ticket_number) AS order_count
FROM filtered_sales f
JOIN tpcds.store s
    ON f.ss_store_sk = s.s_store_sk
JOIN tpcds.customer_address ca
    ON f.ss_addr_sk = ca.ca_address_sk
GROUP BY
    s.s_store_name,
    ca.ca_city,
    regexp_extract(f.c_email_address, '@(.+)$', 1)
ORDER BY total_net_profit DESC
LIMIT 10
