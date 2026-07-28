WITH filtered_customers AS (
   SELECT c.c_customer_sk,
          c.c_customer_id,
          c.c_first_name,
          c.c_last_name
   FROM tpcds.customer c
   WHERE c.c_birth_month = 6
     AND NOT EXISTS (
         SELECT 1
         FROM tpcds.web_page wp
         WHERE wp.wp_customer_sk = c.c_customer_sk
     )
)
SELECT customer_id,
       first_name,
       last_name,
       sales_channel,
       total_net_paid,
       value_flag
FROM (
   SELECT fc.c_customer_id AS customer_id,
          fc.c_first_name AS first_name,
          fc.c_last_name AS last_name,
          'Catalog' AS sales_channel,
          SUM(cs.cs_net_paid) AS total_net_paid,
          CASE WHEN SUM(cs.cs_net_paid) > 1000 THEN 'High' ELSE 'Low' END AS value_flag
   FROM filtered_customers fc
   JOIN tpcds.catalog_sales cs ON cs.cs_bill_customer_sk = fc.c_customer_sk
   JOIN tpcds.time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   WHERE td.t_hour BETWEEN 9 AND 17
   GROUP BY fc.c_customer_id, fc.c_first_name, fc.c_last_name

   UNION ALL

   SELECT fc.c_customer_id AS customer_id,
          fc.c_first_name AS first_name,
          fc.c_last_name AS last_name,
          'Store' AS sales_channel,
          SUM(ss.ss_net_paid) AS total_net_paid,
          CASE WHEN SUM(ss.ss_net_paid) > 1000 THEN 'High' ELSE 'Low' END AS value_flag
   FROM filtered_customers fc
   JOIN tpcds.store_sales ss ON ss.ss_customer_sk = fc.c_customer_sk
   JOIN tpcds.time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   WHERE td.t_hour BETWEEN 9 AND 17
   GROUP BY fc.c_customer_id, fc.c_first_name, fc.c_last_name
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
