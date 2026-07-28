WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_street_name,
        wp.wp_url,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
        CONCAT(s.s_store_name, ' - ', s.s_city) AS store_city
    FROM customer c
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE regexp_like(ca.ca_street_name, '^Elm')
      AND wp.wp_url LIKE '%foo%'
)
SELECT
    fc.store_city,
    COUNT(DISTINCT fc.c_customer_sk) AS num_customers,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(cr.cr_net_loss) AS total_return_loss,
    AVG(CAST(regexp_extract(fc.domain, '\\d+$') AS double)) AS avg_trailing_number_in_domain
FROM filtered_customers fc
JOIN store_sales ss
    ON ss.ss_customer_sk = fc.c_customer_sk
JOIN catalog_returns cr
    ON cr.cr_returning_customer_sk = fc.c_customer_sk
GROUP BY fc.store_city
ORDER BY total_net_paid DESC
LIMIT 10
