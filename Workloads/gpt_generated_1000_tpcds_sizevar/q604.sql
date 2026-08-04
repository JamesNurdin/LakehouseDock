SELECT
    ws.ws_order_number,
    ws.ws_net_paid,
    site.web_name,
    site.web_manager
FROM tpcds.web_sales ws
JOIN tpcds.web_site site
  ON ws.ws_web_site_sk = site.web_site_sk
WHERE ws.ws_list_price > 150
  AND site.web_manager = 'Harold Wilson'
LIMIT 100
