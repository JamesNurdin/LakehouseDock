WITH catalog_agg AS (
   SELECT d.d_year AS year,
          ca.ca_state AS state,
          SUM(cs.cs_net_paid) AS total_net_paid
   FROM catalog_sales cs
   INNER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   INNER JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
     AND ca.ca_state IN ('CA', 'TX')
   GROUP BY d.d_year, ca.ca_state
),
store_agg AS (
   SELECT d.d_year AS year,
          ca.ca_state AS state,
          SUM(ss.ss_net_paid) AS total_net_paid
   FROM store_sales ss
   INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   INNER JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
     AND ca.ca_state IN ('CA', 'TX')
   GROUP BY d.d_year, ca.ca_state
)
SELECT year,
       state,
       total_net_paid
FROM catalog_agg
UNION
SELECT year,
       state,
       total_net_paid
FROM store_agg
ORDER BY year, state
LIMIT 100
