SELECT cp.cp_department,
       ca.ca_state,
       t.t_hour,
       hd.hd_vehicle_count,
       COUNT(DISTINCT cp.cp_catalog_page_id) AS page_cnt,
       AVG(cp.cp_catalog_page_number) AS avg_page_num,
       SUM(CASE WHEN cp.cp_type = 'monthly' THEN 1 ELSE 0 END) AS monthly_cnt,
       SUM(CASE WHEN cp.cp_type = 'quarterly' THEN 1 ELSE 0 END) AS quarterly_cnt
FROM catalog_page cp
JOIN household_demographics hd ON cp.cp_catalog_page_sk = hd.hd_demo_sk
JOIN customer_address ca ON cp.cp_catalog_page_sk = ca.ca_address_sk
JOIN time_dim t ON cp.cp_start_date_sk = t.t_time_sk
WHERE cp.cp_type IN ('monthly', 'quarterly')
  AND cp.cp_department IS NOT NULL
  AND ca.ca_country = 'United States'
  AND t.t_hour BETWEEN 8 AND 20
GROUP BY cp.cp_department, ca.ca_state, t.t_hour, hd.hd_vehicle_count
HAVING COUNT(DISTINCT cp.cp_catalog_page_id) > 10
ORDER BY page_cnt DESC
LIMIT 100
