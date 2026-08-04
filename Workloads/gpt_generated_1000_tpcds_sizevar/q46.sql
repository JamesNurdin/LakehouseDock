SELECT
  w.web_name,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  AVG(ws.ws_net_profit) AS avg_profit
FROM web_sales ws
JOIN web_site w
  ON ws.ws_web_site_sk = w.web_site_sk
WHERE ws.ws_ext_ship_cost > 1000
  AND w.web_country = 'United States'
GROUP BY w.web_name
