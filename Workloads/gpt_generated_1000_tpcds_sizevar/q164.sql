WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
)
SELECT
    regexp_extract(c.c_email_address, '@([^@]+)$', 1) AS email_domain,
    c.c_birth_country,
    cd.cd_credit_rating,
    SUM(ss.ss_net_paid_inc_tax) AS total_paid_inc_tax,
    COUNT(*) AS sales_count
FROM sampled_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year = 2020
  AND c.c_birth_country LIKE 'B%'
  AND regexp_like(c.c_email_address, '^[A-Za-z]+\.[A-Za-z]+@.*\\.org$')
GROUP BY
    regexp_extract(c.c_email_address, '@([^@]+)$', 1),
    c.c_birth_country,
    cd.cd_credit_rating
ORDER BY total_paid_inc_tax DESC
LIMIT 100
