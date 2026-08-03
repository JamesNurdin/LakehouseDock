WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_net_paid,
        c.c_customer_id,
        c.c_email_address,
        c.c_preferred_cust_flag,
        c.c_login,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        -- string processing examples
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1) AS email_domain,
        SUBSTR(c.c_login, 1, 3) AS login_prefix,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
        REGEXP_LIKE(c.c_email_address, '^[A-Z][a-zA-Z0-9._%+-]*@example\\.com$')
        AND c.c_preferred_cust_flag LIKE 'Y%'
        AND d.d_year BETWEEN 2000 AND 2002
)
SELECT
    d_year,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    COUNT(DISTINCT ss_item_sk) AS distinct_items_sold,
    SUM(ss_net_paid) AS total_net_paid,
    CASE WHEN SUM(ss_net_paid) > 100000 THEN 'HIGH' ELSE 'LOW' END AS revenue_category,
    -- include a sample of the string columns for reference (limited by aggregation)
    MIN(email_domain) AS sample_email_domain,
    MIN(login_prefix) AS sample_login_prefix,
    MIN(full_name) AS sample_full_name
FROM filtered_sales
GROUP BY d_year
ORDER BY total_net_paid DESC
LIMIT 100
