WITH sales_2020 AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2020
      AND REGEXP_LIKE(c.c_email_address, '[A-Za-z0-9._%+-]+@[^@]+\\.com$')
      AND LOWER(c.c_first_name) LIKE '%a%'
    GROUP BY c.c_customer_sk,
             CONCAT(c.c_first_name, ' ', c.c_last_name),
             c.c_email_address
)
SELECT
    s.full_name,
    s.c_email_address,
    s.total_net_paid,
    s.distinct_items,
    REGEXP_EXTRACT(s.c_email_address, '([^@]+)@') AS email_user
FROM sales_2020 s
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_customer_sk = s.c_customer_sk
)
ORDER BY s.total_net_paid DESC
LIMIT 100
