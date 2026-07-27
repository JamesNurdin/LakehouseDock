WITH sales_2000 AS (
   SELECT
       ca.ca_state AS state,
       d.d_year AS year,
       SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
       COUNT(CASE WHEN ss.ss_net_paid_inc_tax > 1000 THEN 1 END) AS high_value_count,
       CASE WHEN SUM(ss.ss_net_paid_inc_tax) > 50000 THEN 'HighRevenue' ELSE 'LowRevenue' END AS revenue_category
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE d.d_year = 2000
   GROUP BY ca.ca_state, d.d_year
),
sales_2001 AS (
   SELECT
       ca.ca_state AS state,
       d.d_year AS year,
       SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
       COUNT(CASE WHEN ss.ss_net_paid_inc_tax > 1000 THEN 1 END) AS high_value_count,
       CASE WHEN SUM(ss.ss_net_paid_inc_tax) > 50000 THEN 'HighRevenue' ELSE 'LowRevenue' END AS revenue_category
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE d.d_year = 2001
   GROUP BY ca.ca_state, d.d_year
)
SELECT * FROM sales_2000
UNION ALL
SELECT * FROM sales_2001
ORDER BY state, year
LIMIT 100
