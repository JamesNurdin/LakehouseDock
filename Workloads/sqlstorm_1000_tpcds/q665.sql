WITH catalog AS (
    SELECT d.d_year,
           i.i_brand,
           'Catalog' AS channel,
           SUM(cs.cs_net_profit) AS net_profit,
           SUM(cs.cs_quantity) AS quantity,
           COUNT(*) AS orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_brand
), store AS (
    SELECT d.d_year,
           i.i_brand,
           'Store' AS channel,
           SUM(ss.ss_net_profit) AS net_profit,
           SUM(ss.ss_quantity) AS quantity,
           COUNT(*) AS orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_brand
), web AS (
    SELECT d.d_year,
           i.i_brand,
           'Web' AS channel,
           SUM(ws.ws_net_profit) AS net_profit,
           SUM(ws.ws_quantity) AS quantity,
           COUNT(*) AS orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_brand
), combined AS (
    SELECT d_year, i_brand, channel, net_profit, quantity, orders FROM catalog
    UNION ALL
    SELECT d_year, i_brand, channel, net_profit, quantity, orders FROM store
    UNION ALL
    SELECT d_year, i_brand, channel, net_profit, quantity, orders FROM web
)
SELECT year,
       brand,
       channel,
       net_profit,
       quantity,
       orders,
       SUM(net_profit) OVER (PARTITION BY brand ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM (
    SELECT d_year AS year, i_brand AS brand, channel, net_profit, quantity, orders
    FROM combined
) t
WHERE year BETWEEN 1999 AND 2001
ORDER BY brand, year, channel
FETCH FIRST 500 ROWS ONLY
