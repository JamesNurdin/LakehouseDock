WITH store_channel AS (
    SELECT d.d_year AS d_year,
           i.i_category AS i_category,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 1998
),
catalog_channel AS (
    SELECT d.d_year AS d_year,
           i.i_category AS i_category,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 1998
),
web_channel AS (
    SELECT d.d_year AS d_year,
           i.i_category AS i_category,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 1998
)
SELECT d_year,
       i_category,
       SUM(net_profit) AS total_net_profit
FROM (
    SELECT d_year, i_category, net_profit FROM store_channel
    UNION ALL
    SELECT d_year, i_category, net_profit FROM catalog_channel
    UNION ALL
    SELECT d_year, i_category, net_profit FROM web_channel
) combined
GROUP BY d_year, i_category
ORDER BY total_net_profit DESC
LIMIT 10
