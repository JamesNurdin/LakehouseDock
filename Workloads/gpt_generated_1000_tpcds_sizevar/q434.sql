SELECT
  web_site_id,
  web_name,
  web_state,
  web_mkt_id,
  web_gmt_offset
FROM tpcds.web_site
WHERE web_state = 'CA'
  AND web_mkt_id = 5
