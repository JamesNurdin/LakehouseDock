SELECT DISTINCT
    web_site.web_company_name,
    web_site.web_state,
    web_site.web_country,
    web_site.web_tax_percentage
FROM web_site
WHERE web_site.web_company_id IN (1, 2)
  AND web_site.web_tax_percentage > 5.00
  AND web_site.web_street_number IN ('671', '358')
LIMIT 100
