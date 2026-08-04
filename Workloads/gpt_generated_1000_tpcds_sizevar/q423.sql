WITH scalar_max_year AS (
   SELECT MAX(d_year) AS max_year
   FROM date_dim
   WHERE d_quarter_name = '1901Q1'
),
first_part AS (
   SELECT
       cp.cp_department,
       cp.cp_catalog_page_number,
       d.d_year,
       SUM(i.inv_quantity_on_hand) AS total_qty,
       AVG(i.inv_quantity_on_hand) AS avg_qty,
       COUNT(*) AS cnt,
       ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY SUM(i.inv_quantity_on_hand) DESC) AS dept_rank,
       l.adjusted_qty
   FROM catalog_page cp
   JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
   JOIN inventory i ON i.inv_date_sk = d.d_date_sk
   CROSS JOIN LATERAL (
       SELECT i.inv_quantity_on_hand * 1.1 AS adjusted_qty
   ) l
   WHERE cp.cp_department = 'Books'
     AND cp.cp_catalog_page_number >= 10
     AND d.d_current_month = 'Y'
     AND d.d_following_holiday = 'N'
     AND i.inv_quantity_on_hand > 600
     AND d.d_year = (SELECT max_year FROM scalar_max_year)
   GROUP BY cp.cp_department, cp.cp_catalog_page_number, d.d_year, l.adjusted_qty
),
second_part AS (
   SELECT
       cp.cp_department,
       cp.cp_catalog_page_number,
       d.d_year,
       SUM(i.inv_quantity_on_hand) AS total_qty,
       AVG(i.inv_quantity_on_hand) AS avg_qty,
       COUNT(*) AS cnt,
       ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY SUM(i.inv_quantity_on_hand) DESC) AS dept_rank,
       l.adjusted_qty
   FROM catalog_page cp
   JOIN date_dim d ON cp.cp_end_date_sk = d.d_date_sk
   JOIN inventory i ON i.inv_date_sk = d.d_date_sk
   CROSS JOIN LATERAL (
       SELECT i.inv_quantity_on_hand * 0.9 AS adjusted_qty
   ) l
   WHERE cp.cp_department = 'Electronics'
     AND cp.cp_catalog_page_number <= 16
     AND d.d_current_month = 'N'
     AND d.d_following_holiday = 'Y'
     AND i.inv_quantity_on_hand < 800
     AND d.d_year = (SELECT max_year FROM scalar_max_year)
   GROUP BY cp.cp_department, cp.cp_catalog_page_number, d.d_year, l.adjusted_qty
)
SELECT
    u.cp_department,
    u.cp_catalog_page_number,
    u.d_year,
    u.total_qty,
    u.avg_qty,
    u.cnt,
    u.dept_rank,
    u.adjusted_qty
FROM (
    SELECT * FROM first_part
    UNION
    SELECT * FROM second_part
) u
ORDER BY u.total_qty DESC
LIMIT 100
