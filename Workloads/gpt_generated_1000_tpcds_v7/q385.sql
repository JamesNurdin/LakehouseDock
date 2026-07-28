WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        SUM(cs.cs_net_paid) AS total_paid,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
        MAX(d.d_date) AS last_purchase_date,
        REGEXP_EXTRACT(c.c_email_address, '@([^@]+)$') AS email_domain
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE REGEXP_LIKE(c.c_email_address, '^[A-Za-z0-9._%+-]+@([A-Za-z0-9.-]+)\\.com$')
      AND c.c_salutation LIKE 'Mr.%'
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        REGEXP_EXTRACT(c.c_email_address, '@([^@]+)$')
)
SELECT
    cs.c_customer_id,
    cs.full_name,
    cs.email_domain,
    cs.total_paid,
    cs.distinct_items,
    cs.last_purchase_date
FROM customer_sales cs
ORDER BY cs.total_paid DESC
LIMIT 100
