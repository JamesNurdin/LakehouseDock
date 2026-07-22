SELECT
  i.i_brand,
  i.i_category,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  AVG(ws.ws_ext_sales_price) AS avg_sales,
  COUNT(*) AS order_count,
  MIN(ws.ws_ext_sales_price) AS min_sales,
  MAX(ws.ws_ext_sales_price) AS max_sales,
  CASE WHEN SUM(ws.ws_ext_sales_price) > (SELECT AVG(ws2.ws_ext_sales_price) FROM tpcds.web_sales ws2) THEN 'Above Overall Avg' ELSE 'Below Overall Avg' END AS sales_vs_overall
FROM tpcds.web_sales ws
JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
WHERE ws.ws_ext_list_price > 5000
  AND ws.ws_sales_price < 30
  AND ws.ws_web_site_sk IN (5, 7, 13)
  AND i.i_size = 'large'
  AND i.i_manufact_id = 212
GROUP BY i.i_brand, i.i_category
ORDER BY total_sales DESC
LIMIT 100
