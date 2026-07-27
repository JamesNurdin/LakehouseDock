SELECT
    wsite.web_name,
    SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
    COUNT(*) AS order_cnt
FROM tpcds.web_sales ws
JOIN tpcds.web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE wsite.web_site_id = 'AAAAAAAAPBAAAAAA'
  AND wsite.web_tax_percentage > 0.05
  AND ws.ws_ext_ship_cost > 500
GROUP BY wsite.web_name
ORDER BY total_ship_cost DESC
