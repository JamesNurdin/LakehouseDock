WITH promo_sales AS (
    SELECT
        s.s_store_id AS store_id,
        CONCAT(s.s_store_name, ' ', s.s_state) AS store_full_name,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS net_paid,
        CASE WHEN SUM(ss.ss_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS revenue_category,
        'promo' AS sales_type,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2022
      AND regexp_like(p.p_promo_name, '^Promo[0-9]+$')
      AND c.c_email_address LIKE '%@example.com'
      AND s.s_store_name LIKE '%Store%'
    GROUP BY s.s_store_id,
             CONCAT(s.s_store_name, ' ', s.s_state),
             d.d_year,
             regexp_extract(c.c_email_address, '@(.+)$', 1)
),
nonpromo_sales AS (
    SELECT
        s.s_store_id AS store_id,
        CONCAT(s.s_store_name, ' ', s.s_state) AS store_full_name,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS net_paid,
        CASE WHEN SUM(ss.ss_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS revenue_category,
        'nonpromo' AS sales_type,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2022
      AND NOT regexp_like(p.p_promo_name, '^Promo[0-9]+$')
      AND c.c_email_address LIKE '%@example.com'
      AND s.s_store_name LIKE '%Store%'
    GROUP BY s.s_store_id,
             CONCAT(s.s_store_name, ' ', s.s_state),
             d.d_year,
             regexp_extract(c.c_email_address, '@(.+)$', 1)
)
SELECT *
FROM promo_sales
UNION ALL
SELECT *
FROM nonpromo_sales
ORDER BY store_id, year, sales_type
