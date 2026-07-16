SELECT s.s_state AS state,
       COUNT(DISTINCT s.s_store_sk) AS store_count,
       SUM(s.s_floor_space) AS total_floor_space,
       AVG(s.s_number_employees) AS avg_employees,
       COUNT(DISTINCT w.web_site_sk) AS website_count,
       AVG(w.web_tax_percentage) AS avg_website_tax_pct,
       AVG(w.web_gmt_offset) AS avg_website_gmt_offset
FROM store s
JOIN web_site w
  ON s.s_state = w.web_state
WHERE s.s_country = 'United States'
  AND w.web_country = 'United States'
  AND s.s_state IN ('SD', 'MN', 'NE', 'AL', 'NC')
GROUP BY s.s_state
HAVING COUNT(DISTINCT s.s_store_sk) >= 5
ORDER BY total_floor_space DESC
LIMIT 10
