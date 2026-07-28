WITH filtered_sales AS (
   SELECT
       cp.cp_department AS department,
       d.d_day_name AS day_name,
       cs.cs_net_profit AS net_profit,
       regexp_extract(cp.cp_description, '(\\d{3})', 1) AS code3,
       concat(cp.cp_department, '_', d.d_day_name) AS dept_day
   FROM tpcds.catalog_sales cs
   JOIN tpcds.catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN tpcds.date_dim d
       ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN tpcds.time_dim t
       ON cs.cs_sold_time_sk = t.t_time_sk
   WHERE regexp_like(cp.cp_description, '\\d{3}')
     AND cp.cp_type LIKE 'A%'
     AND t.t_meal_time = 'dinner'
)
SELECT
    department,
    day_name,
    code3,
    sum(net_profit) AS total_profit,
    count(*) AS sales_cnt,
    max(dept_day) AS example_concat
FROM filtered_sales
GROUP BY department, day_name, code3
ORDER BY total_profit DESC
LIMIT 100
