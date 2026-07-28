WITH sales AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        ss.ss_net_profit,
        d.d_year
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
      AND REGEXP_LIKE(c.c_first_name, '^[A-M].*')
      AND c.c_email_address LIKE '%@example.com'
)
SELECT
    customer_id,
    full_name,
    COUNT(*) AS sales_count,
    SUM(ss_net_profit) AS total_profit,
    MAX(d_year) AS latest_year,
    SUBSTRING(email_domain, 2) AS domain_without_at
FROM (
    SELECT
        c_customer_id AS customer_id,
        full_name,
        ss_net_profit,
        d_year,
        REGEXP_EXTRACT(c_email_address, '(@.+)$') AS email_domain
    FROM sales
) sub
GROUP BY customer_id, full_name, email_domain
ORDER BY total_profit DESC
LIMIT 100
