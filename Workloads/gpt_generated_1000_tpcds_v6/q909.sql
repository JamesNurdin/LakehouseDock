SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    'sold' AS sales_type
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_dom IN (20, 21)
  AND ws.ws_ext_sales_price > 1000
GROUP BY d.d_year, d.d_month_seq

UNION ALL

SELECT
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    'ship' AS sales_type
FROM web_sales ws
JOIN date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
WHERE d.d_dow = 1
  AND ws.ws_quantity > 5
GROUP BY d.d_year, d.d_month_seq

ORDER BY year DESC, month_seq DESC, sales_type
LIMIT 100
