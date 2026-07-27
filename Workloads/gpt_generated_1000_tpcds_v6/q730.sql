WITH catalog_agg AS (
   SELECT
      'Catalog' AS source_type,
      d.d_year AS year,
      SUM(cs.cs_ext_sales_price) AS total_sales
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE cp.cp_department = 'DEPARTMENT'
     AND cp.cp_end_date_sk IN (2451361, 2451144)
     AND d.d_year BETWEEN 1998 AND 2000
   GROUP BY d.d_year
),
store_agg AS (
   SELECT
      'Store' AS source_type,
      d.d_year AS year,
      SUM(ss.ss_ext_sales_price) AS total_sales
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE s.s_state = 'CA'
     AND d.d_year BETWEEN 1998 AND 2000
     AND EXISTS (
         SELECT 1 FROM store s2
         WHERE s2.s_store_sk = s.s_store_sk
           AND s2.s_number_employees > 50
     )
   GROUP BY d.d_year
)
SELECT source_type, year, total_sales
FROM (
   SELECT source_type, year, total_sales FROM catalog_agg
   UNION ALL
   SELECT source_type, year, total_sales FROM store_agg
) combined
ORDER BY year DESC, total_sales DESC
LIMIT 100
