WITH sales_first_half AS (
   SELECT
       cp.cp_department AS department,
       d.d_year AS year,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_category,
       COUNT(DISTINCT hd.hd_vehicle_count) AS distinct_vehicle_counts
   FROM catalog_sales cs
   JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 1999
     AND d.d_month_seq BETWEEN 1 AND 6
     AND hd.hd_dep_count >= 3
   GROUP BY cp.cp_department, d.d_year
),
sales_night_shift AS (
   SELECT
       cp.cp_department AS department,
       d.d_year AS year,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       CASE WHEN SUM(cs.cs_ext_sales_price) > 50000 THEN 'High' ELSE 'Low' END AS sales_category,
       COUNT(DISTINCT hd.hd_vehicle_count) AS distinct_vehicle_counts
   FROM catalog_sales cs
   JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN household_demographics hd
     ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
   JOIN time_dim t
     ON cs.cs_sold_time_sk = t.t_time_sk
   WHERE d.d_year = 1999
     AND t.t_shift = 'Night'
     AND hd.hd_vehicle_count >= 0
   GROUP BY cp.cp_department, d.d_year
)
SELECT *
FROM (
   SELECT * FROM sales_first_half
   UNION ALL
   SELECT * FROM sales_night_shift
) AS combined
ORDER BY total_sales DESC
LIMIT 100
