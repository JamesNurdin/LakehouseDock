WITH sales_union AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_quantity AS quantity,
         cs.cs_net_paid AS net_paid,
         cs.cs_net_profit AS net_profit,
         'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_item_sk,
         ss.ss_quantity,
         ss.ss_net_paid,
         ss.ss_net_profit,
         'store' AS channel
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_item_sk,
         ws.ws_quantity,
         ws.ws_net_paid,
         ws.ws_net_profit,
         'web' AS channel
  FROM web_sales ws
)
SELECT d.d_year,
       d.d_month_seq,
       s.channel,
       i.i_category,
       SUM(s.net_profit) AS total_profit,
       SUM(s.net_paid) AS total_paid,
       COUNT(*) AS sales_cnt,
       AVG(s.quantity) AS avg_quantity
FROM sales_union s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
GROUP BY ROLLUP (d.d_year, d.d_month_seq, s.channel, i.i_category)
ORDER BY total_profit DESC
LIMIT 100
