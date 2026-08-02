SELECT
  web_state,
  COUNT(*) AS site_count,
  AVG(web_tax_percentage) AS avg_tax_percentage
FROM web_site
WHERE web_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
  AND web_company_id IN (1, 4)
GROUP BY web_state
HAVING COUNT(*) > 0
ORDER BY site_count DESC
LIMIT 100
