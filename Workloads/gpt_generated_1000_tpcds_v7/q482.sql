SELECT 'catalog' AS channel,
       SUM(cs.cs_net_paid) AS total_net_paid
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_type = 'monthly'

UNION ALL

SELECT 'web' AS channel,
       SUM(ws.ws_net_paid) AS total_net_paid
FROM web_sales ws
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_rec_end_date >= DATE '2000-01-01'
