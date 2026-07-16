SELECT d.d_year, f.channel, SUM(f.net_profit) AS total_net_profit
FROM (
    SELECT ss_sold_date_sk AS date_sk, ss_net_profit AS net_profit, 'store' AS channel FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk, ws_net_profit, 'web' FROM web_sales
    UNION ALL
    SELECT cs_sold_date_sk, cs_net_profit, 'catalog' FROM catalog_sales
) f
JOIN date_dim d ON d.d_date_sk = f.date_sk
GROUP BY d.d_year, f.channel
ORDER BY d.d_year, f.channel
