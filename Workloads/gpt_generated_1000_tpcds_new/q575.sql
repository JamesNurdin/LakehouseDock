WITH sales1 AS (
   SELECT
       d.d_year AS year,
       ca.ca_state AS state,
       ss.ss_customer_sk AS customer_sk,
       ss.ss_ext_sales_price AS ext_sales_price,
       ss.ss_quantity AS quantity,
       (SELECT SUM(ws.ws_ext_sales_price)
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = ss.ss_customer_sk) AS related_sales_total
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE ss.ss_ext_sales_price > (SELECT AVG(cs.cs_ext_sales_price) FROM catalog_sales cs)
     AND NOT EXISTS (
         SELECT 1 FROM warehouse w WHERE w.w_state = ca.ca_state
     )
),
agg1 AS (
   SELECT
       year,
       state,
       COUNT(DISTINCT customer_sk) AS distinct_customer_cnt,
       SUM(DISTINCT ext_sales_price) AS sum_distinct_sales,
       AVG(quantity) AS avg_quantity,
       SUM(related_sales_total) AS total_related_sales
   FROM sales1
   GROUP BY year, state
),
sales2 AS (
   SELECT
       d.d_year AS year,
       ca.ca_state AS state,
       cs.cs_bill_customer_sk AS customer_sk,
       cs.cs_ext_sales_price AS ext_sales_price,
       cs.cs_quantity AS quantity,
       (SELECT SUM(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = cs.cs_bill_customer_sk) AS related_sales_total
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   WHERE cs.cs_ext_sales_price > (SELECT AVG(cs.cs_ext_sales_price) FROM catalog_sales cs)
     AND NOT EXISTS (
         SELECT 1 FROM warehouse w WHERE w.w_state = ca.ca_state
     )
),
agg2 AS (
   SELECT
       year,
       state,
       COUNT(DISTINCT customer_sk) AS distinct_customer_cnt,
       SUM(DISTINCT ext_sales_price) AS sum_distinct_sales,
       AVG(quantity) AS avg_quantity,
       SUM(related_sales_total) AS total_related_sales
   FROM sales2
   GROUP BY year, state
)
SELECT
    ROW_NUMBER() OVER (ORDER BY year DESC, state) AS rn,
    u.year,
    u.state,
    u.distinct_customer_cnt,
    u.sum_distinct_sales,
    u.avg_quantity,
    u.total_related_sales
FROM (
    SELECT * FROM agg1
    UNION
    SELECT * FROM agg2
) u
ORDER BY rn
LIMIT 100
