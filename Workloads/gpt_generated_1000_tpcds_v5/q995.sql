WITH filtered_sales AS (
    SELECT
        cs.cs_net_paid_inc_tax,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_credit_rating,
        td.t_shift,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE regexp_like(c.c_email_address, '@[^@]+\\.com$')
      AND c.c_last_name LIKE 'A%'
)
SELECT
    cd_credit_rating,
    t_shift,
    SUM(cs_net_paid_inc_tax) AS total_net_paid,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    COUNT(DISTINCT email_domain) AS distinct_email_domains,
    ARRAY_AGG(DISTINCT concat(c_first_name, ' ', c_last_name)) FILTER (WHERE c_first_name IS NOT NULL) AS sample_customer_names
FROM filtered_sales
GROUP BY cd_credit_rating, t_shift
ORDER BY total_net_paid DESC
LIMIT 100
