WITH years_array AS (
   SELECT ARRAY[2000, 2001, 2002] AS years
),
years AS (
   SELECT y AS year_val
   FROM years_array
   CROSS JOIN UNNEST(years) AS t(y)
),
store_sales_agg AS (
   SELECT
       'store' AS source_type,
       s.s_store_id AS entity_id,
       s.s_store_name AS entity_desc,
       COALESCE(SUM(ss.ss_net_paid), 0) AS total_net_paid,
       d.d_year AS year
   FROM store s
   RIGHT OUTER JOIN store_sales ss
       ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN date_dim d
       ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001 OR d.d_year IS NULL
   GROUP BY s.s_store_id, s.s_store_name, d.d_year
),
catalog_sales_agg AS (
   SELECT
       'catalog' AS source_type,
       cp.cp_catalog_page_id AS entity_id,
       cp.cp_description AS entity_desc,
       COALESCE(SUM(cs.cs_net_paid), 0) AS total_net_paid,
       d.d_year AS year
   FROM catalog_page cp
   RIGHT OUTER JOIN catalog_sales cs
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN date_dim d
       ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001 OR d.d_year IS NULL
   GROUP BY cp.cp_catalog_page_id, cp.cp_description, d.d_year
),
union_all AS (
   SELECT * FROM store_sales_agg
   UNION ALL
   SELECT * FROM catalog_sales_agg
)
SELECT
   u.source_type,
   u.entity_id,
   u.entity_desc,
   u.total_net_paid,
   u.year,
   y.year_val AS cross_year
FROM union_all u
CROSS JOIN years y
ORDER BY u.source_type, u.total_net_paid DESC
OFFSET 0
LIMIT 100
