SELECT
    d.d_day_name,
    d.d_date,
    SUM(ws.ws_net_paid_inc_ship) AS total_net_paid_inc_ship,
    AVG(ws.ws_ext_list_price) AS avg_ext_list_price
FROM web_sales ws
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_fy_quarter_seq = 15
  AND ws.ws_ext_list_price > 1000
GROUP BY d.d_day_name, d.d_date
ORDER BY total_net_paid_inc_ship DESC
LIMIT 100
