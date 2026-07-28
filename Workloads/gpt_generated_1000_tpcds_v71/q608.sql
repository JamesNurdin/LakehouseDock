WITH recent_years AS (
    SELECT d_date_sk, d_year
    FROM tpcds.date_dim
    WHERE d_year IN (2000, 2001, 2002)
)
SELECT 'store' AS sales_channel,
       dy.d_year,
       SUM(ss.ss_net_paid) AS total_net_paid,
       SUM(ss.ss_net_profit) AS total_net_profit
FROM tpcds.store_sales ss
JOIN recent_years dy ON ss.ss_sold_date_sk = dy.d_date_sk
JOIN tpcds.time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
WHERE ss.ss_quantity > 2
  AND td.t_hour BETWEEN 9 AND 17
GROUP BY dy.d_year

UNION ALL

SELECT 'web' AS sales_channel,
       dy.d_year,
       SUM(ws.ws_net_paid) AS total_net_paid,
       SUM(ws.ws_net_profit) AS total_net_profit
FROM tpcds.web_sales ws
JOIN recent_years dy ON ws.ws_sold_date_sk = dy.d_date_sk
JOIN tpcds.time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
WHERE ws.ws_quantity > 2
  AND td.t_hour BETWEEN 9 AND 17
GROUP BY dy.d_year

ORDER BY sales_channel, d_year
LIMIT 100
