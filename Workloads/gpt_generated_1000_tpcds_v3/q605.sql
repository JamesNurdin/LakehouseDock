WITH customer_sales AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        COUNT(*) AS order_count
    FROM
        catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND REGEXP_LIKE(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
        AND c.c_first_name LIKE 'A%'
    GROUP BY
        cs.cs_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender
)
SELECT
    CONCAT(cs.c_first_name, ' ', cs.c_last_name) AS full_name,
    cs.c_email_address,
    SUBSTRING(cs.c_email_address FROM 1 FOR POSITION('@' IN cs.c_email_address) - 1) AS email_user,
    CASE WHEN cs.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_label,
    cs.total_net_paid,
    cs.order_count,
    CASE 
        WHEN cs.total_net_paid > (SELECT AVG(total_net_paid) FROM customer_sales) THEN 'High Spender'
        ELSE 'Low Spender'
    END AS spender_category,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM store_sales ss
            JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
            WHERE ss.ss_customer_sk = cs.customer_sk
              AND d2.d_year = 2002
        ) THEN 'Has 2002 Store Sales'
        ELSE 'No 2002 Store Sales'
    END AS store_sales_2002_flag
FROM
    customer_sales cs
ORDER BY
    cs.total_net_paid DESC
LIMIT 100
