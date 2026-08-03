WITH sales_customers AS (
    SELECT DISTINCT c.c_customer_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
),
returns_customers AS (
    SELECT DISTINCT c.c_customer_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
    UNION
    SELECT DISTINCT c.c_customer_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
),
web_return_customers AS (
    SELECT DISTINCT c.c_customer_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
),
sales_without_returns AS (
    SELECT c_customer_sk FROM sales_customers
    EXCEPT
    SELECT c_customer_sk FROM returns_customers
),
sales_and_web_returns AS (
    SELECT c_customer_sk FROM sales_customers
    INTERSECT
    SELECT c_customer_sk FROM web_return_customers
)
SELECT swr.c_customer_sk,
       cust_info.first_name,
       cust_info.birth_year,
       sales_sum.total_sales,
       'sales_without_returns' AS category
FROM sales_without_returns swr
CROSS JOIN LATERAL (
    SELECT SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_customer_sk = swr.c_customer_sk
      AND d.d_year = 2002
) sales_sum
CROSS JOIN LATERAL (
    SELECT c.c_first_name AS first_name,
           c.c_birth_year AS birth_year
    FROM customer c
    WHERE c.c_customer_sk = swr.c_customer_sk
) cust_info
UNION ALL
SELECT swr.c_customer_sk,
       cust_info.first_name,
       cust_info.birth_year,
       sales_sum.total_sales,
       'sales_and_web_returns' AS category
FROM sales_and_web_returns swr
CROSS JOIN LATERAL (
    SELECT SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_customer_sk = swr.c_customer_sk
      AND d.d_year = 2002
) sales_sum
CROSS JOIN LATERAL (
    SELECT c.c_first_name AS first_name,
           c.c_birth_year AS birth_year
    FROM customer c
    WHERE c.c_customer_sk = swr.c_customer_sk
) cust_info
ORDER BY total_sales DESC, c_customer_sk
