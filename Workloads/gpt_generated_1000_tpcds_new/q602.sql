SELECT
  w.web_name,
  SUM(ws.ws_net_profit) AS total_net_profit,
  COUNT(DISTINCT ws.ws_order_number) AS order_count,
  AVG(ws.ws_ext_tax) AS avg_ext_tax
FROM tpcds.web_sales ws
JOIN tpcds.web_site w
  ON ws.ws_web_site_sk = w.web_site_sk
WHERE w.web_zip = '33511'
  AND ws.ws_ext_tax > 50
GROUP BY w.web_name
ORDER BY total_net_profit DESC
LIMIT 10
