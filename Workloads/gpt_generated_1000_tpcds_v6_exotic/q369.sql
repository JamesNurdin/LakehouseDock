WITH filtered_store_returns AS (
    SELECT
        sr.sr_net_loss,
        sr.sr_customer_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE REGEXP_LIKE(r.r_reason_desc, '(?i)damage|defect')
), enriched AS (
    SELECT
        sr.sr_net_loss,
        c.c_customer_sk,
        c.c_email_address,
        s.s_store_name AS store_name,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1) AS email_domain
    FROM filtered_store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE c.c_email_address LIKE '%@%'
)
SELECT
    store_name,
    email_domain,
    CONCAT('Domain: ', email_domain) AS domain_label,
    SUM(sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers
FROM enriched
GROUP BY store_name, email_domain, CONCAT('Domain: ', email_domain)
ORDER BY total_net_loss DESC
LIMIT 100
