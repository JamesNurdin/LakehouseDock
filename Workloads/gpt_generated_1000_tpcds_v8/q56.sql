SELECT
  web_state,
  COUNT(*) AS site_count
FROM tpcds.web_site
WHERE web_market_manager = 'Casey Banks'
  AND web_state IN ('PA', 'NY')
GROUP BY web_state
ORDER BY site_count DESC
