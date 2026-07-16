WITH unified_sales AS (
    SELECT ss_sold_date_sk AS sold_date_sk,
           ss_item_sk AS item_sk,
           ss_net_profit AS net_profit,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_net_profit,
           'web'
    FROM web_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_item_sk,
           cs_net_profit,
           'catalog'
    FROM catalog_sales
)
SELECT d.d_year,
       i.i_category,
       SUM(CASE WHEN u.channel = 'store' THEN u.net_profit END) AS store_net_profit,
       SUM(CASE WHEN u.channel = 'web' THEN u.net_profit END) AS web_net_profit,
       SUM(CASE WHEN u.channel = 'catalog' THEN u.net_profit END) AS catalog_net_profit,
       SUM(u.net_profit) AS total_net_profit
FROM unified_sales u
JOIN date_dim d ON u.sold_date_sk = d.d_date_sk
JOIN item i ON u.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY d.d_year, i.i_category
ORDER BY d.d_year, i.i_category
