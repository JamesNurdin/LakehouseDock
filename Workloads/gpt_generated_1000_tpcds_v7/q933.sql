WITH store_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1) AS email_domain
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE c.c_email_address LIKE '%@example.com'
      AND c.c_first_name LIKE 'A%'
      AND REGEXP_LIKE(p.p_promo_name, '\\bDiscount\\b')
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1)
)
SELECT
    s_store_id,
    s_store_name,
    total_net_profit,
    total_net_paid,
    distinct_customers,
    email_domain
FROM store_agg
WHERE total_net_profit > (
    SELECT AVG(ss2.ss_net_profit)
    FROM store_sales ss2
)
ORDER BY total_net_profit DESC
LIMIT 20
