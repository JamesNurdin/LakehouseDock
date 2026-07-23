WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        ss.ss_cdemo_sk
    FROM store_sales ss
    WHERE ss.ss_net_paid > 0
)
SELECT
    s.s_store_id,
    s.s_market_manager,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location,
    substring(s.s_zip, 1, 3) AS zip_prefix,
    d.d_year,
    regexp_extract(p.p_promo_name, '(\\d{4})', 1) AS promo_year,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM filtered_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE
    regexp_like(s.s_market_manager, '^(Dean|Michael)')
    AND regexp_like(c.c_email_address, '@(gmail|yahoo)\\.com$')
    AND d.d_year = 2001
    AND regexp_like(p.p_promo_name, '\\d{4}')
GROUP BY
    s.s_store_id,
    s.s_market_manager,
    CONCAT(s.s_city, ', ', s.s_state),
    substring(s.s_zip, 1, 3),
    d.d_year,
    regexp_extract(p.p_promo_name, '(\\d{4})', 1)
ORDER BY total_net_paid DESC
LIMIT 100
