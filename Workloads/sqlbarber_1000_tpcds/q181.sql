SELECT d.d_year AS year,
       w.web_name AS site_name,
       SUM(ws.ws_net_paid) AS total_net_paid,
       COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM web_sales ws
INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
INNER JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
WHERE d.d_year = 1911
  AND w.web_state = 'AL'
GROUP BY d.d_year, w.web_name
