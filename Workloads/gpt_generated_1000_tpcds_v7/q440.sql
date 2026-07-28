SELECT
  w.web_site_id,
  ws.ws_web_site_sk,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  COUNT(*) AS order_count,
  'market_3' AS segment
FROM web_sales ws
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
WHERE w.web_mkt_id = 3
GROUP BY w.web_site_id, ws.ws_web_site_sk

UNION ALL

SELECT
  w.web_site_id,
  ws.ws_web_site_sk,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  COUNT(*) AS order_count,
  'tax_gt_100' AS segment
FROM web_sales ws
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
WHERE ws.ws_ext_tax > 100
GROUP BY w.web_site_id, ws.ws_web_site_sk
LIMIT 100
