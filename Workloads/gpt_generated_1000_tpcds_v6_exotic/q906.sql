WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_addr_sk,
        ss.ss_ext_sales_price,
        ca.ca_state,
        ca.ca_city,
        ca.ca_street_name,
        c.c_email_address,
        d.d_year,
        d.d_date
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2020
      AND regexp_like(c.c_email_address, '^.*@[^@]+\\.com$')
      AND ca.ca_city LIKE 'M%'
),
agg_sales AS (
    SELECT
        ca_state,
        ca_city,
        d_year,
        regexp_extract(ca_street_name, '\\d+') AS street_number,
        SUM(ss_ext_sales_price) AS total_sales
    FROM filtered_sales
    GROUP BY
        ca_state,
        ca_city,
        d_year,
        regexp_extract(ca_street_name, '\\d+')
)
SELECT
    ca_state,
    ca_city,
    d_year,
    street_number,
    total_sales,
    RANK() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS state_city_sales_rank
FROM agg_sales
ORDER BY
    total_sales DESC,
    ca_state,
    ca_city
