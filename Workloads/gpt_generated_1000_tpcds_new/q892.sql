SELECT
    ws.web_site_id,
    ws.web_name,
    ws.web_city,
    ws.web_state,
    ws.web_gmt_offset
FROM tpcds.web_site AS ws
WHERE ws.web_rec_start_date >= DATE '2000-01-01'
  AND ws.web_mkt_id IN (1, 2, 3)
ORDER BY ws.web_gmt_offset DESC
LIMIT 10
