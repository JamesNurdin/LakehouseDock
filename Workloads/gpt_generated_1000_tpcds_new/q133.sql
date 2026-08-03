WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_email_address,
        substr(c.c_first_name, 1, 1) || '.' || c.c_last_name AS name_key,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        cd.cd_marital_status,
        SUM(ss.ss_net_paid) AS total_spent
    FROM tpcds.customer c
    JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.store_sales ss
        ON c.c_customer_sk = ss.ss_customer_sk
    JOIN tpcds.date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND regexp_like(c.c_email_address, '^.+@example\\.com$')
      AND c.c_first_name LIKE 'A%'
    GROUP BY c.c_customer_sk,
             c.c_customer_id,
             c.c_email_address,
             c.c_first_name,
             c.c_last_name,
             cd.cd_marital_status
),
returns_customers AS (
    SELECT DISTINCT cr.cr_refunded_customer_sk AS c_customer_sk
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND cr.cr_return_amount > 0
),
final_set AS (
    SELECT
        fc.c_customer_sk,
        fc.c_customer_id,
        fc.email_domain,
        fc.name_key,
        fc.total_spent
    FROM filtered_customers fc
    EXCEPT
    SELECT
        rc.c_customer_sk,
        CAST(NULL AS varchar),
        CAST(NULL AS varchar),
        CAST(NULL AS varchar),
        CAST(NULL AS decimal(7,2))
    FROM returns_customers rc
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS row_num,
    c_customer_id,
    email_domain,
    name_key,
    total_spent
FROM final_set
ORDER BY total_spent DESC
LIMIT 100
