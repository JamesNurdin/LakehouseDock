WITH domain_customers AS (
    SELECT DISTINCT
        c.c_customer_sk,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^@]+)\\.', 1) AS domain_name,
        regexp_extract(c.c_email_address, '\\.[^.]*)$', 1) AS domain_tld,
        concat(regexp_extract(c.c_email_address, '@([^@]+)\\.', 1), '.', regexp_extract(c.c_email_address, '\\.[^.]*)$', 1)) AS domain_full
    FROM customer c
    WHERE regexp_like(c.c_email_address, '^[A-Za-z]+\\.[A-Za-z]+@.*\\.(org|edu|com)$')
      AND c.c_email_address LIKE '%@%.org'
),
sales_without_returns AS (
    SELECT ss_ticket_number
    FROM store_sales
    EXCEPT
    SELECT sr_ticket_number
    FROM store_returns
),
sales_agg AS (
    SELECT
        dc.domain_full,
        d.d_year,
        COUNT(DISTINCT dc.c_customer_sk) AS num_customers,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE
            WHEN SUM(ss.ss_net_paid_inc_tax) > 50000 THEN 'HIGH'
            ELSE 'LOW'
        END AS sales_category
    FROM domain_customers dc
    JOIN store_sales ss ON ss.ss_customer_sk = dc.c_customer_sk
    JOIN sales_without_returns swo ON ss.ss_ticket_number = swo.ss_ticket_number
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ROLLUP (dc.domain_full, d.d_year)
)
SELECT
    domain_full,
    d_year,
    num_customers,
    total_sales,
    total_profit,
    sales_category
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
