SELECT web_state,
       COUNT(*) AS site_count
FROM tpcds.web_site
WHERE web_country = 'United States'
  AND web_street_type = 'Ave'
GROUP BY web_state
ORDER BY site_count DESC
