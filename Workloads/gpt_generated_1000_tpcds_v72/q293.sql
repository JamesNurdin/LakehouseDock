SELECT ws.web_name,
       ws.web_city,
       d.d_year,
       d.d_current_quarter
FROM web_site ws
JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_current_quarter = 'Y'
  AND ws.web_gmt_offset = -5.00
ORDER BY ws.web_name
LIMIT 100
