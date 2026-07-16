WITH sales AS (
    SELECT ss.ss_sold_date_sk AS sold_date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_net_profit AS net_profit,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_net_profit,
           'web'
    FROM web_sales ws
    UNION ALL
    SELECT cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_net_profit,
           'catalog'
    FROM catalog_sales cs
)
SELECT
    d.d_year,
    i.i_category,
    s.channel,
    SUM(s.net_profit) AS total_net_profit
FROM sales s
JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY CUBE (d.d_year, i.i_category, s.channel)
ORDER BY total_net_profit DESC
LIMIT 100
