WITH all_sales AS (
  SELECT ss_sold_date_sk AS sold_date_sk,
         ss_item_sk AS item_sk,
         ss_net_paid AS net_paid,
         ss_net_profit AS net_profit,
         'store' AS channel
  FROM store_sales
  UNION ALL
  SELECT cs_sold_date_sk,
         cs_item_sk,
         cs_net_paid,
         cs_net_profit,
         'catalog'
  FROM catalog_sales
  UNION ALL
  SELECT ws_sold_date_sk,
         ws_item_sk,
         ws_net_paid,
         ws_net_profit,
         'web'
  FROM web_sales
)
SELECT d.d_year,
       i.i_category,
       i.i_class,
       all_sales.channel,
       SUM(all_sales.net_paid) AS total_net_paid,
       SUM(all_sales.net_profit) AS total_net_profit,
       AVG(all_sales.net_profit / NULLIF(all_sales.net_paid, 0)) AS profit_margin
FROM all_sales
JOIN date_dim d ON all_sales.sold_date_sk = d.d_date_sk
JOIN item i ON all_sales.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year, i.i_category, i.i_class, all_sales.channel
ORDER BY d.d_year, i.i_category, i.i_class, all_sales.channel
