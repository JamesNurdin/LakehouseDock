SELECT ws.web_state,
       COUNT(DISTINCT ws.web_site_sk) AS sites_opened
FROM web_site ws
JOIN date_dim d
  ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_current_quarter = 'Y'
  AND ws.web_state IN ('CA', 'TX')
GROUP BY ws.web_state
ORDER BY sites_opened DESC
