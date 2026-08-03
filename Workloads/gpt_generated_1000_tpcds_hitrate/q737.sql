WITH recent_returns AS (
   SELECT cr.cr_refunded_customer_sk AS customer_sk
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
top_stores AS (
   SELECT s_store_sk
   FROM store
   WHERE s_number_employees > 500
   ORDER BY s_number_employees DESC
   LIMIT 10
)
SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       r.r_reason_desc,
       (
         SELECT avg(ss2.ss_net_paid)
         FROM store_sales ss2
         WHERE ss2.ss_customer_sk = c.c_customer_sk
       ) AS avg_spent
FROM (
   SELECT ss.ss_customer_sk AS customer_sk
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND ss.ss_store_sk IN (SELECT s_store_sk FROM top_stores)
   INTERSECT
   SELECT customer_sk FROM recent_returns
) ic
JOIN customer c ON ic.customer_sk = c.c_customer_sk
CROSS JOIN (
   SELECT r_reason_desc
   FROM reason
   WHERE r_reason_id IN ('R001', 'R002', 'R003')
) r
ORDER BY c.c_customer_id
OFFSET 0 LIMIT 100
