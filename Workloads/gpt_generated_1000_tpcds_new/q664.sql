SELECT d.d_year,
       d.d_quarter_name,
       COUNT(*) AS order_cnt,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       SUM(ws.ws_quantity) AS total_qty
FROM web_sales ws
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
WHERE ws.ws_ship_hdemo_sk = 5684
  AND d.d_year = 1904
  AND d.d_quarter_name = '1904Q4'
GROUP BY d.d_year, d.d_quarter_name
ORDER BY total_sales DESC
