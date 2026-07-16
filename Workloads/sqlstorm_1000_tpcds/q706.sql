SELECT wp.wp_type,
       d.d_month_seq,
       SUM(ws.ws_net_paid) AS total_sales
FROM web_sales ws
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
GROUP BY wp.wp_type, d.d_month_seq
ORDER BY total_sales DESC
LIMIT 5
