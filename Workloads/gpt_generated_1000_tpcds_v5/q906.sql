WITH sales_enriched AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_quantity,
        c.c_customer_sk,
        c.c_email_address,
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        p.p_promo_name,
        regexp_extract(c.c_email_address, '@([^\\.]+\\..+)$', 1) AS email_domain,
        regexp_extract(i.i_product_name, '(\\w+)-\\w+', 1) AS product_prefix
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(c.c_email_address, '^.+@.+\\.(com|net|org)$')
      AND i.i_product_name LIKE '%-RED-%'
)
SELECT
    email_domain,
    product_prefix,
    CONCAT(email_domain, '_', product_prefix) AS domain_product_key,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_quantity) AS total_quantity,
    COUNT(DISTINCT p_promo_name) AS distinct_promos
FROM sales_enriched
GROUP BY
    email_domain,
    product_prefix,
    CONCAT(email_domain, '_', product_prefix)
HAVING SUM(ss_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
