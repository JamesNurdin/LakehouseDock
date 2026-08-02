WITH sales_base AS (
   SELECT
       ss.ss_customer_sk AS customer_sk,
       cd.cd_gender AS gender,
       SUM(ss.ss_net_paid_inc_tax) AS total_sales
   FROM store_sales ss
   TABLESAMPLE BERNOULLI (10)
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
     AND d.d_current_quarter = 'Y'
     AND cd.cd_gender = 'F'
   GROUP BY ss.ss_customer_sk, cd.cd_gender
   HAVING SUM(ss.ss_net_paid_inc_tax) > 500.00
),
sales_agg AS (
   SELECT
       customer_sk,
       gender,
       total_sales,
       RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
   FROM sales_base
),
returns_agg AS (
   SELECT
       cr.cr_returning_customer_sk AS customer_sk,
       cd.cd_gender AS gender,
       SUM(cr.cr_net_loss) AS total_net_loss,
       SUM(cr.cr_return_amount) AS total_return_amount
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
     AND d.d_current_quarter = 'Y'
     AND cd.cd_gender = 'F'
   GROUP BY cr.cr_returning_customer_sk, cd.cd_gender
   HAVING SUM(cr.cr_net_loss) > 100.00
),
intersected_customers AS (
   SELECT customer_sk, gender
   FROM sales_agg
   INTERSECT
   SELECT customer_sk, gender
   FROM returns_agg
)
SELECT
   ic.customer_sk,
   ic.gender,
   sa.total_sales,
   ra.total_net_loss,
   ROW_NUMBER() OVER (PARTITION BY ic.gender ORDER BY sa.total_sales DESC) AS row_num_per_gender
FROM intersected_customers ic
JOIN sales_agg sa ON ic.customer_sk = sa.customer_sk AND ic.gender = sa.gender
JOIN returns_agg ra ON ic.customer_sk = ra.customer_sk AND ic.gender = ra.gender
ORDER BY ra.total_net_loss DESC
LIMIT 100
