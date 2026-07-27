WITH sales_web AS (
    SELECT
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        c.c_customer_sk,
        c.c_email_address,
        p.p_promo_name,
        ws.web_name,
        ws.web_city
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
      AND c.c_email_address LIKE '%@example.com'
      AND regexp_like(p.p_promo_name, '(?i)holiday')
)
SELECT
    CONCAT('Site ', web_name) AS site_label,
    web_city,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    MIN(REGEXP_EXTRACT(c_email_address, '@([^.]*)\\.', 1)) AS sample_email_domain,
    MIN(p_promo_name) AS example_promo_name
FROM sales_web
GROUP BY web_name, web_city
HAVING SUM(cs_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 10
