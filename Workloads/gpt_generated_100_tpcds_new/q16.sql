WITH sales_customers AS (
    SELECT DISTINCT c.c_customer_id AS customer_id
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
),
return_customers AS (
    SELECT DISTINCT c.c_customer_id AS customer_id
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
)
SELECT customer_id
FROM sales_customers
EXCEPT
SELECT customer_id
FROM return_customers
ORDER BY customer_id
