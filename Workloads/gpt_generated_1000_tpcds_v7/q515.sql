WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_net_profit,
        ss.ss_sold_date_sk
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2021
), qualified_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        ca.ca_address_sk,
        ca.ca_zip
    FROM tpcds.customer c
    JOIN tpcds.customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE REGEXP_LIKE(c.c_email_address, '@example\\.com$')
          AND ca.ca_zip LIKE '9%'
)
SELECT
    s.s_store_id,
    s.s_store_name,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location,
    REGEXP_EXTRACT(ca.ca_zip, '^([0-9]{3})', 1) AS zip_prefix,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
FROM filtered_sales ss
JOIN qualified_customers c ON ss.ss_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
WHERE s.s_store_name LIKE '%Market%'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ca.ca_zip
ORDER BY total_profit DESC
LIMIT 100
