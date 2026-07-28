SELECT DISTINCT
    web_name,
    web_city,
    web_state
FROM tpcds.web_site
WHERE web_mkt_class LIKE '%Necessary%'
  AND web_zip = '33511'
