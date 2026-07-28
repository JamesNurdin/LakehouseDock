WITH avg_discount AS (
   SELECT AVG(cs_ext_discount_amt) AS avg_disc
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
sales_data AS (
   SELECT
       s.s_store_id,
       d.d_year,
       SUM(ss.ss_ext_sales_price) AS total_amount,
       CASE WHEN SUM(ss.ss_ext_sales_price) > 0 THEN 'Sales' ELSE 'Zero' END AS record_type,
       (SELECT avg_disc FROM avg_discount) AS avg_catalog_discount
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE d.d_year = 2001
   GROUP BY s.s_store_id, d.d_year
   HAVING SUM(ss.ss_ext_sales_price) > 10000
),
returns_data AS (
   SELECT
       s.s_store_id,
       d.d_year,
       -SUM(sr.sr_return_amt) AS total_amount,
       CASE WHEN SUM(sr.sr_return_amt) > 0 THEN 'Return' ELSE 'Zero' END AS record_type,
       (SELECT avg_disc FROM avg_discount) AS avg_catalog_discount
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   WHERE d.d_year = 2001
   GROUP BY s.s_store_id, d.d_year
   HAVING SUM(sr.sr_return_amt) > 5000
)
SELECT DISTINCT *
FROM (
   SELECT * FROM sales_data
   UNION ALL
   SELECT * FROM returns_data
) combined
LIMIT 100
