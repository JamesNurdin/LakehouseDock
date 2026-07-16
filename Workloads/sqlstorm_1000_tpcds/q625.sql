SELECT i.i_category, d.d_year, SUM(ws.ws_net_paid) AS total_sales
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
GROUP BY i.i_category, d.d_year
ORDER BY total_sales DESC
LIMIT 10
