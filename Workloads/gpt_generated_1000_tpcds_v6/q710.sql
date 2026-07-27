WITH cust_email AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_email_address,
        c.c_current_cdemo_sk,
        c.c_first_sales_date_sk,
        regexp_extract(c.c_email_address, '@([^@]+)$', 1) AS email_domain
    FROM tpcds.customer c
    WHERE regexp_like(c.c_email_address, '@[a-z0-9]+\\.(com|net|org)$')
)
SELECT
    s.s_division_name,
    s.s_market_desc,
    COUNT(DISTINCT ce.c_customer_sk) AS total_customers,
    COUNT(DISTINCT CASE WHEN ce.email_domain = 'example.com' THEN ce.c_customer_sk END) AS example_com_customers,
    ARRAY_AGG(DISTINCT ce.email_domain) FILTER (WHERE ce.email_domain IS NOT NULL) AS distinct_domains
FROM tpcds.store s
JOIN tpcds.date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN cust_email ce
    ON ce.c_first_sales_date_sk = d_closed.d_date_sk
JOIN tpcds.customer_demographics cd
    ON ce.c_current_cdemo_sk = cd.cd_demo_sk
WHERE
    d_closed.d_year = 2002
    AND d_closed.d_holiday = 'N'
    AND regexp_like(s.s_market_desc, '^[A-Z].*')
    AND s.s_market_desc LIKE '%the%'
    AND substring(ce.c_first_name, 1, 1) = 'A'
    AND cd.cd_gender = 'M'
GROUP BY
    s.s_division_name,
    s.s_market_desc
HAVING
    COUNT(DISTINCT ce.c_customer_sk) > 10
ORDER BY
    total_customers DESC
LIMIT 100
