SELECT d.d_year,
       i.i_category,
       sum(ws.ws_net_paid) AS total_sales
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year, i.i_category
ORDER BY d.d_year, i.i_category
