WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUBSTRING(c.c_last_name, 1, 1) AS last_initial,
        c.c_email_address,
        s.s_store_name,
        i.i_category,
        d.d_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2022
      AND c.c_first_name LIKE 'A%'
      AND regexp_like(c.c_email_address, '^.+@.+\\.com$')
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUBSTRING(c.c_last_name, 1, 1),
        c.c_email_address,
        s.s_store_name,
        i.i_category,
        d.d_year
)
SELECT
    cs.c_customer_sk,
    CONCAT(cs.c_first_name, ' ', cs.c_last_name) AS full_name,
    cs.last_initial,
    cs.s_store_name,
    cs.i_category,
    cs.total_net_paid,
    cs.num_transactions,
    email.email_domain,
    RANK() OVER (ORDER BY cs.total_net_paid DESC) AS sales_rank
FROM customer_sales cs
CROSS JOIN LATERAL (
    SELECT regexp_extract(cs.c_email_address, '@(.+)$', 1) AS email_domain
) AS email
WHERE email.email_domain LIKE '%.com'
ORDER BY cs.total_net_paid DESC
LIMIT 100
