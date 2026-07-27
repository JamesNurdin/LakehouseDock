SELECT web_site_id,
       web_name,
       web_city,
       web_tax_percentage
FROM tpcds.web_site
WHERE web_mkt_id = 4
  AND web_tax_percentage > 0.02
ORDER BY web_tax_percentage DESC
