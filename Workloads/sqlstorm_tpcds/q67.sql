SELECT d.d_year, SUM(ws.ws_ext_sales_price) AS total_sales
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year
ORDER BY d.d_year
