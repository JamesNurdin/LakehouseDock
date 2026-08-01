WITH catalog AS (
   SELECT
       d.d_year,
       c.c_birth_country AS region,
       i.i_item_desc,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE regexp_like(i.i_item_desc, '^[A-Z]{2}.*')
     AND c.c_birth_country LIKE 'B%'
   GROUP BY d.d_year, c.c_birth_country, i.i_item_desc
),
store AS (
   SELECT
       d.d_year,
       s.s_store_name AS region,
       i.i_item_desc,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE s.s_store_name LIKE '%Mart%'
     AND substring(i.i_item_desc, 1, 5) = 'Large'
   GROUP BY d.d_year, s.s_store_name, i.i_item_desc
)
SELECT DISTINCT
    year,
    region,
    item_desc,
    total_sales,
    sales_rank
FROM (
   SELECT d_year AS year,
          region,
          i_item_desc AS item_desc,
          total_sales,
          sales_rank
   FROM catalog
   UNION ALL
   SELECT d_year AS year,
          region,
          i_item_desc AS item_desc,
          total_sales,
          sales_rank
   FROM store
) combined
ORDER BY total_sales DESC
LIMIT 100
