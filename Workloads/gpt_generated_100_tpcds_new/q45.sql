SELECT
    td.t_hour,
    td.t_am_pm,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_tax) AS total_tax
FROM web_sales ws
JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
WHERE td.t_am_pm = 'PM'
  AND ws.ws_ext_tax > 20.00
GROUP BY td.t_hour, td.t_am_pm
ORDER BY total_sales DESC
LIMIT 10
