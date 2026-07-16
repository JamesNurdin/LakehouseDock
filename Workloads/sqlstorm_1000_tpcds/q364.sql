SELECT d.d_year,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       SUM(ws.ws_ext_discount_amt) AS total_discount,
       COUNT(*) AS order_cnt
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year
ORDER BY d.d_year
