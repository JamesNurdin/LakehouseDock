SELECT d.d_year,
       i.i_category,
       s.channel,
       SUM(s.net_profit) AS total_profit,
       SUM(s.quantity) AS total_quantity,
       COUNT(*) AS sales_count
FROM (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_quantity AS quantity,
         cs.cs_net_paid AS net_paid,
         cs.cs_net_profit AS net_profit,
         cs.cs_promo_sk AS promo_sk,
         'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_item_sk,
         ss.ss_quantity,
         ss.ss_net_paid,
         ss.ss_net_profit,
         ss.ss_promo_sk,
         'store'
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_item_sk,
         ws.ws_quantity,
         ws.ws_net_paid,
         ws.ws_net_profit,
         ws.ws_promo_sk,
         'web'
  FROM web_sales ws
) s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
GROUP BY d.d_year, i.i_category, s.channel
ORDER BY d.d_year, total_profit DESC
LIMIT 200
