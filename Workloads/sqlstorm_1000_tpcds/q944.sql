WITH all_sales AS (
    SELECT ss.ss_sold_date_sk AS sold_date_sk,
           ss.ss_net_profit AS net_profit,
           ss.ss_ext_sales_price AS ext_sales_price,
           ss.ss_item_sk AS item_sk,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_net_profit,
           ws.ws_ext_sales_price,
           ws.ws_item_sk,
           'web' AS channel
    FROM web_sales ws
    UNION ALL
    SELECT cs.cs_sold_date_sk,
           cs.cs_net_profit,
           cs.cs_ext_sales_price,
           cs.cs_item_sk,
           'catalog' AS channel
    FROM catalog_sales cs
)
SELECT d.d_year,
       d.d_moy AS month,
       s.channel,
       i.i_category,
       SUM(s.net_profit) AS total_net_profit,
       SUM(s.ext_sales_price) AS total_sales,
       COUNT(*) AS transaction_count
FROM all_sales s
JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
GROUP BY d.d_year, d.d_moy, s.channel, i.i_category
ORDER BY d.d_year, d.d_moy, s.channel, i.i_category
