WITH unified_sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_net_profit,
           'store'
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_net_profit,
           'web'
    FROM web_sales ws
)
SELECT d.d_year,
       i.i_category,
       i.i_brand,
       SUM(CASE WHEN us.channel = 'catalog' THEN us.net_profit ELSE 0 END) AS catalog_net_profit,
       SUM(CASE WHEN us.channel = 'store' THEN us.net_profit ELSE 0 END) AS store_net_profit,
       SUM(CASE WHEN us.channel = 'web' THEN us.net_profit ELSE 0 END) AS web_net_profit,
       SUM(us.net_profit) AS total_net_profit
FROM unified_sales us
JOIN date_dim d ON us.date_sk = d.d_date_sk
JOIN item i ON us.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year, i.i_category, i.i_brand
ORDER BY d.d_year, i.i_category, i.i_brand
