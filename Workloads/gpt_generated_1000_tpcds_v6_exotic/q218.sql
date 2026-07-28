WITH sales_agg AS (
    SELECT
        d.d_year,
        cd.cd_gender,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        ANY_VALUE(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS example_full_name,
        ANY_VALUE(regexp_extract(c.c_email_address, '@([A-Za-z0-9.-]+)\\.', 1)) AS example_email_domain,
        ANY_VALUE(substr(c.c_last_name, 1, 1)) AS example_last_initial,
        ANY_VALUE(ca.ca_city) AS example_city
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(c.c_email_address, '\\d{3,}')
      AND ca.ca_city LIKE 'New%'
      AND d.d_year BETWEEN 2001 AND 2002
    GROUP BY GROUPING SETS (
        (d.d_year, cd.cd_gender),
        (d.d_year),
        ()
    )
)
SELECT
    d_year,
    cd_gender,
    total_sales,
    distinct_customers,
    example_full_name,
    example_email_domain,
    example_last_initial,
    example_city,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY d_year, cd_gender, total_sales DESC
LIMIT 100
