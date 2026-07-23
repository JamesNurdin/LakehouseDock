WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ca.ca_city,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        CASE
            WHEN regexp_like(c.c_email_address, '.*@example\\.com$') THEN 'Example'
            WHEN regexp_like(c.c_email_address, '.*@gmail\\.com$') THEN 'Gmail'
            ELSE 'Other'
        END AS email_domain_category,
        regexp_extract(c.c_email_address, '@([^\\.]+)\\.', 1) AS email_domain_prefix,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE ca.ca_city LIKE '%York%'
      AND regexp_like(c.c_email_address, '@[A-Za-z0-9.-]+\\.(com|net|org)$')
)
SELECT
    d.d_year,
    fc.email_domain_category,
    substring(fc.ca_city, 1, 3) AS city_prefix,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders,
    CASE
        WHEN SUM(ss.ss_net_profit) > 1000000 THEN 'High'
        WHEN SUM(ss.ss_net_profit) > 500000  THEN 'Medium'
        ELSE 'Low'
    END AS profit_bucket
FROM filtered_customers fc
JOIN tpcds.store_sales ss ON ss.ss_customer_sk = fc.c_customer_sk
JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year,
         fc.email_domain_category,
         substring(fc.ca_city, 1, 3)
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY d.d_year ASC,
         total_net_profit DESC
