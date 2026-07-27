SELECT
  ws.web_state,
  dd.d_year,
  COUNT(ws.web_site_id) AS site_count,
  AVG(ws.web_tax_percentage) AS avg_tax_pct
FROM web_site ws
JOIN date_dim dd ON ws.web_open_date_sk = dd.d_date_sk
WHERE dd.d_year BETWEEN 1999 AND 2001
  AND ws.web_state IN ('OH', 'GA')
GROUP BY ws.web_state, dd.d_year
ORDER BY dd.d_year DESC, ws.web_state
LIMIT 100
