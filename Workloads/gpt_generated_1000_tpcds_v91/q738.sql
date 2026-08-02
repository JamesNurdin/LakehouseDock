SELECT ws.web_site_id,
       ws.web_name,
       ws.web_company_id,
       dd.d_date AS open_date,
       dd.d_quarter_name
FROM web_site ws
JOIN date_dim dd ON ws.web_open_date_sk = dd.d_date_sk
WHERE dd.d_quarter_name = '1904Q3'
  AND ws.web_company_id = 3
ORDER BY ws.web_name ASC
LIMIT 100
