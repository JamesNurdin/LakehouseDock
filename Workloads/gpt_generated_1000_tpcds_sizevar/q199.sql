SELECT
  ws.ws_order_number,
  ws.ws_ext_sales_price,
  ws_site.web_name,
  ws_site.web_tax_percentage
FROM web_sales ws
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE ws_site.web_tax_percentage = 0.07
  AND ws.ws_ext_list_price > 3000
ORDER BY ws.ws_ext_sales_price DESC
LIMIT 10
