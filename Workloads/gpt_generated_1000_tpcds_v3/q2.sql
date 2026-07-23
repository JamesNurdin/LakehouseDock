WITH filtered_address AS (
    SELECT
        ca_address_sk,
        ca_state,
        ca_city,
        ca_street_number,
        ca_street_name,
        ca_street_type,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_street,
        SUBSTR(ca_zip, 1, 5) AS zip_prefix,
        REGEXP_EXTRACT(ca_suite_number, 'Suite (\\d+)', 1) AS suite_number_extracted
    FROM
        customer_address
    WHERE
        ca_city LIKE 'A%'
        AND REGEXP_LIKE(ca_suite_number, '^Suite [0-9]*0$')
        AND REGEXP_LIKE(ca_street_type, 'Way|Rd|Blvd')
)
SELECT
    d.d_year,
    d.d_month_seq,
    a.ca_state,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(*) AS sales_count,
    MAX(a.full_street) AS example_street,
    MAX(a.zip_prefix) AS example_zip_prefix,
    MAX(a.suite_number_extracted) AS example_suite_number
FROM
    catalog_sales cs
    JOIN filtered_address a ON cs.cs_ship_addr_sk = a.ca_address_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE
    d.d_year = 2000
GROUP BY
    d.d_year,
    d.d_month_seq,
    a.ca_state
ORDER BY
    total_net_profit DESC,
    d.d_year,
    d.d_month_seq
LIMIT 100
