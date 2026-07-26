WITH unified AS (
  SELECT cc.cc_company AS company_id,
         'CallCenter' AS entity_type,
         cc.cc_employees AS employees,
         cc.cc_sq_ft AS floor_space,
         cc.cc_tax_percentage AS tax_pct,
         cc.cc_gmt_offset AS gmt_offset
  FROM call_center cc
  UNION ALL
  SELECT s.s_company_id AS company_id,
         'Store' AS entity_type,
         s.s_number_employees AS employees,
         s.s_floor_space AS floor_space,
         s.s_tax_percentage AS tax_pct,
         s.s_gmt_offset AS gmt_offset
  FROM store s
  UNION ALL
  SELECT w.web_company_id AS company_id,
         'WebSite' AS entity_type,
         0 AS employees,
         0 AS floor_space,
         w.web_tax_percentage AS tax_pct,
         w.web_gmt_offset AS gmt_offset
  FROM web_site w
)
SELECT company_id,
       SUM(employees) AS total_employees,
       SUM(floor_space) AS total_floor_space,
       AVG(tax_pct) AS avg_tax_percentage,
       AVG(gmt_offset) AS avg_gmt_offset,
       DENSE_RANK() OVER (ORDER BY SUM(employees) DESC) AS employee_rank,
       CASE
         WHEN SUM(employees) >= 5000 THEN 'Enterprise'
         WHEN SUM(employees) >= 1000 THEN 'Large'
         WHEN SUM(employees) >= 200 THEN 'Medium'
         ELSE 'Small'
       END AS company_size_category
FROM unified
GROUP BY company_id
HAVING SUM(employees) > 0
ORDER BY employee_rank
LIMIT 20
