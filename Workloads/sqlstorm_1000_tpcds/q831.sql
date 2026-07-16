SELECT channel,
       d.d_year,
       SUM(net_paid) AS total_net_paid,
       SUM(net_profit) AS total_net_profit,
       COUNT(*) AS order_count
FROM (
   SELECT 'store' AS channel,
          ss.ss_sold_date_sk AS sold_date_sk,
          ss.ss_net_paid AS net_paid,
          ss.ss_net_profit AS net_profit
   FROM store_sales ss
   UNION ALL
   SELECT 'catalog' AS channel,
          cs.cs_sold_date_sk,
          cs.cs_net_paid,
          cs.cs_net_profit
   FROM catalog_sales cs
   UNION ALL
   SELECT 'web' AS channel,
          ws.ws_sold_date_sk,
          ws.ws_net_paid,
          ws.ws_net_profit
   FROM web_sales ws
) s
JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY channel, d.d_year
