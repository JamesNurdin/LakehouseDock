WITH store_data AS (
    SELECT d.d_year AS year,
           'store' AS channel,
           ss.ss_net_paid_inc_tax AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_quantity > 0
      AND d.d_year = 2001
),
web_data AS (
    SELECT d.d_year AS year,
           'web' AS channel,
           ws.ws_net_paid_inc_tax AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_quantity > 0
      AND d.d_year = 2001
)
SELECT combined.year,
       combined.channel,
       SUM(combined.profit) AS total_profit
FROM (
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM web_data
) AS combined
GROUP BY combined.year, combined.channel
HAVING SUM(combined.profit) > 10000
ORDER BY combined.year, combined.channel
