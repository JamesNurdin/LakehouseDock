SELECT ws_site.web_site_id,
       SUM(ws.ws_net_paid) AS total_net_paid
FROM web_sales ws
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE ws_site.web_state = 'GA'
  AND ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2001
    )
GROUP BY ws_site.web_site_id
ORDER BY total_net_paid DESC
LIMIT 10
