SELECT
  web_state,
  COUNT(DISTINCT web_name) AS distinct_site_count,
  AVG(web_gmt_offset) AS avg_gmt_offset
FROM tpcds.web_site
WHERE web_open_date_sk = 2450747
  AND web_street_type = 'Avenue'
GROUP BY web_state
ORDER BY distinct_site_count DESC, web_state
LIMIT 100
