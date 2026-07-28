WITH sales_agg AS (
       SELECT
           ss.ss_customer_sk AS customer_sk,
           SUM(ss.ss_net_paid_inc_tax) AS total_sales,
           MIN(d.d_year) AS first_year
       FROM store_sales ss
       JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
       WHERE ss.ss_quantity > 0
       GROUP BY ss.ss_customer_sk
   ),
   web_sales_agg AS (
       SELECT
           ws.ws_bill_customer_sk AS customer_sk,
           SUM(ws.ws_net_paid_inc_tax) AS total_sales,
           MIN(d.d_year) AS first_year
       FROM web_sales ws
       JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
       WHERE ws.ws_quantity > 0
       GROUP BY ws.ws_bill_customer_sk
   ),
   combined_sales AS (
       SELECT customer_sk, total_sales, first_year FROM sales_agg
       UNION ALL
       SELECT customer_sk, total_sales, first_year FROM web_sales_agg
   ),
   customer_totals AS (
       SELECT
           cs.customer_sk,
           SUM(cs.total_sales) AS total_sales,
           MIN(cs.first_year) AS first_year
       FROM combined_sales cs
       GROUP BY cs.customer_sk
   )
SELECT
   c.c_customer_id,
   CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
   c.c_email_address,
   regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
   ca.ca_city,
   CASE
       WHEN regexp_like(ca.ca_city, '^San') THEN 'West Coast'
       ELSE 'Other'
   END AS region_category,
   ct.total_sales,
   ct.first_year,
   (SELECT AVG(total_sales) FROM customer_totals) AS avg_customer_sales
FROM customer_totals ct
JOIN customer c ON ct.customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ca.ca_city LIKE '%York%'
  AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
          AND cr.cr_returned_date_sk = (
                SELECT MAX(d2.d_date_sk)
                FROM date_dim d2
                WHERE d2.d_year = 2020
          )
    )
ORDER BY ct.total_sales DESC
LIMIT 100
