WITH sampled_catalog AS (
   SELECT cs.cs_sold_date_sk,
          cs.cs_net_profit,
          cs.cs_bill_customer_sk
   FROM catalog_sales cs
   TABLESAMPLE BERNOULLI (10)
   WHERE cs.cs_sold_date_sk IS NOT NULL
),
common_customers AS (
   SELECT DISTINCT cs_bill_customer_sk AS customer_sk
   FROM sampled_catalog
   INTERSECT
   SELECT DISTINCT ss_customer_sk
   FROM store_sales
),
union_sales AS (
   SELECT d.d_year AS year,
          'Catalog' AS sales_source,
          cs.cs_net_profit AS net_profit
   FROM sampled_catalog cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE cs.cs_bill_customer_sk IN (SELECT customer_sk FROM common_customers)

   UNION DISTINCT

   SELECT d.d_year AS year,
          'Store' AS sales_source,
          ss.ss_net_profit AS net_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE ss.ss_customer_sk IN (SELECT customer_sk FROM common_customers)
)
SELECT
   year,
   sales_source,
   SUM(net_profit) AS total_net_profit
FROM union_sales
GROUP BY ROLLUP(year, sales_source)
ORDER BY year ASC NULLS LAST,
         sales_source ASC NULLS LAST
