SELECT ws.ws_order_number,
       ws.ws_ext_sales_price,
       ws.ws_net_profit,
       site.web_name,
       site.web_state
FROM tpcds.web_sales ws
JOIN tpcds.web_site site
  ON ws.ws_web_site_sk = site.web_site_sk
WHERE ws.ws_ext_ship_cost > 1000
  AND site.web_state = 'TX'
LIMIT 100
