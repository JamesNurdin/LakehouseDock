SELECT d.d_year AS year,
       SUM(ws.ws_net_paid) AS total_net_paid,
       CASE WHEN SUM(ws.ws_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE wsite.web_state = 'CA'
  AND d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year
UNION ALL
SELECT d.d_year AS year,
       SUM(ss.ss_net_paid) AS total_net_paid,
       CASE WHEN SUM(ss.ss_net_paid) > 8000 THEN 'High' ELSE 'Low' END AS profit_category
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE ca.ca_location_type = 'single family'
  AND d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year
ORDER BY year, total_net_paid DESC
LIMIT 100
