SELECT t.d_year,
       t.channel,
       SUM(t.sales) AS total_sales,
       SUM(t.profit) AS total_profit
FROM (
    SELECT d.d_year AS d_year,
           'store' AS channel,
           ss.ss_net_paid AS sales,
           ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk

    UNION ALL

    SELECT d.d_year,
           'catalog' AS channel,
           cs.cs_net_paid AS sales,
           cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk

    UNION ALL

    SELECT d.d_year,
           'web' AS channel,
           ws.ws_net_paid AS sales,
           ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
) t
WHERE t.d_year = 2001
GROUP BY t.d_year, t.channel
ORDER BY total_sales DESC
LIMIT 10
