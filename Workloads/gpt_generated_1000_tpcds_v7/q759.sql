WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^.]*)\\..*$', 1) AS email_domain,
        ca.ca_country,
        c.c_first_name,
        c.c_last_name
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE regexp_like(c.c_email_address, '^.*@example\\.com$')
),

customer_pages AS (
    SELECT
        fc.c_customer_sk,
        fc.c_email_address,
        fc.email_domain,
        fc.ca_country,
        wp.wp_url
    FROM filtered_customers fc
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = fc.c_customer_sk
    WHERE wp.wp_url LIKE '%promo%'
)

SELECT
    cp.ca_country,
    cp.email_domain,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_cnt,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    CONCAT('Country: ', cp.ca_country) AS country_label
FROM customer_pages cp
JOIN tpcds.store_returns sr
    ON sr.sr_customer_sk = cp.c_customer_sk
JOIN tpcds.reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%defect%'
GROUP BY cp.ca_country, cp.email_domain
ORDER BY total_net_loss DESC
LIMIT 10
