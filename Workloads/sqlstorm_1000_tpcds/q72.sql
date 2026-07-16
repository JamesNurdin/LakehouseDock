SELECT d.d_year,
       i.i_category,
       SUM(CASE WHEN s.src = 'catalog' THEN s.net_profit END) AS catalog_net_profit,
       SUM(CASE WHEN s.src = 'store' THEN s.net_profit END) AS store_net_profit,
       SUM(CASE WHEN s.src = 'web' THEN s.net_profit END) AS web_net_profit,
       SUM(s.net_profit) AS total_net_profit
FROM (
    SELECT cs_sold_date_sk AS sold_date_sk,
           cs_item_sk AS item_sk,
           cs_net_profit AS net_profit,
           'catalog' AS src
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_net_profit,
           'store'
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_net_profit,
           'web'
    FROM web_sales
) AS s
JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year, i.i_category
ORDER BY d.d_year, i.i_category
LIMIT 100
