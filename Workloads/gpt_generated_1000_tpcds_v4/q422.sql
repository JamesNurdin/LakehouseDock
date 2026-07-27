WITH sales_customers AS (
   SELECT
       c.c_customer_id,
       c.c_email_address,
       d_sales.d_date AS activity_date,
       s.s_store_name AS description
   FROM customer c
   JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
   JOIN store s ON s.s_closed_date_sk = d_sales.d_date_sk
   WHERE d_sales.d_year = 2000
     AND s.s_country = 'United States'
),
web_activity AS (
   SELECT
       c.c_customer_id,
       c.c_email_address,
       d_access.d_date AS activity_date,
       wp.wp_url AS description
   FROM web_page wp
   JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
   JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
   WHERE d_access.d_year = 2000
     AND c.c_email_address LIKE '%@%.org'
     AND wp.wp_char_count > 1000
)
SELECT *
FROM sales_customers
UNION ALL
SELECT *
FROM web_activity
LIMIT 100
