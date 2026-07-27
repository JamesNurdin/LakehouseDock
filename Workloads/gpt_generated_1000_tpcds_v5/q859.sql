WITH sales AS (
   SELECT
       cp.cp_department AS department,
       t.t_meal_time AS meal_time,
       SUM(cs.cs_ext_sales_price) AS sales_amount,
       CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
       'Sale' AS record_type
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   WHERE cs.cs_sold_date_sk BETWEEN 2450690 AND 2452167
   GROUP BY cp.cp_department, t.t_meal_time
),
returns AS (
   SELECT
       cp.cp_department AS department,
       t.t_meal_time AS meal_time,
       -SUM(cr.cr_return_amount) AS sales_amount,
       CASE WHEN SUM(cr.cr_net_loss) > 5000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
       'Return' AS record_type
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   WHERE cr.cr_returned_date_sk BETWEEN 2450690 AND 2452167
   GROUP BY cp.cp_department, t.t_meal_time
)
SELECT *
FROM sales
UNION ALL
SELECT *
FROM returns
ORDER BY department, meal_time, record_type
LIMIT 100
