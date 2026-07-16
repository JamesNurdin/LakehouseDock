WITH cust_sales AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_net_paid,
       c.c_email_address,
       lower(trim(split(c.c_email_address, '@')[2])) AS email_domain,
       c.c_first_name,
       c.c_last_name,
       c.c_salutation,
       p.p_promo_name
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2001
     AND c.c_email_address IS NOT NULL
),
aggregated AS (
   SELECT
       email_domain,
       COUNT(DISTINCT ss_ticket_number) AS order_cnt,
       SUM(ss_net_paid) AS total_sales,
       AVG(ss_net_paid) AS avg_order_sales,
       any_value(p_promo_name) AS promo_name,
       any_value(c_first_name) AS first_name,
       any_value(c_last_name) AS last_name,
       any_value(c_salutation) AS salutation
   FROM cust_sales
   GROUP BY email_domain
   HAVING COUNT(DISTINCT ss_ticket_number) > 5
),
ranked AS (
   SELECT
       email_domain,
       order_cnt,
       total_sales,
       avg_order_sales,
       promo_name,
       first_name,
       last_name,
       salutation,
       RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
   FROM aggregated
)
SELECT
   email_domain,
   order_cnt,
   total_sales,
   avg_order_sales,
   CONCAT('Domain=', email_domain) AS domain_label,
   promo_name,
   first_name,
   last_name,
   salutation,
   sales_rank
FROM ranked
ORDER BY sales_rank
