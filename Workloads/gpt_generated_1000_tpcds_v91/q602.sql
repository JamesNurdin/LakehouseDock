SELECT ws.web_company_name,
       dd.d_year,
       COUNT(DISTINCT dd.d_date) AS open_day_count
FROM web_site ws
JOIN date_dim dd
  ON ws.web_open_date_sk = dd.d_date_sk
WHERE ws.web_mkt_id = 2
  AND dd.d_dow = 3
GROUP BY ws.web_company_name, dd.d_year
ORDER BY ws.web_company_name, dd.d_year
LIMIT 100
