WITH sales AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_net_profit AS profit,
         cs.cs_quantity AS quantity,
         'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_item_sk,
         ss.ss_net_profit,
         ss.ss_quantity,
         'store'
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_item_sk,
         ws.ws_net_profit,
         ws.ws_quantity,
         'web'
  FROM web_sales ws
),
returns AS (
  SELECT cr.cr_returned_date_sk AS date_sk,
         cr.cr_item_sk AS item_sk,
         -cr.cr_net_loss AS profit,
         -cr.cr_return_quantity AS quantity,
         'catalog' AS channel
  FROM catalog_returns cr
  UNION ALL
  SELECT sr.sr_returned_date_sk,
         sr.sr_item_sk,
         -sr.sr_net_loss,
         -sr.sr_return_quantity,
         'store'
  FROM store_returns sr
  UNION ALL
  SELECT wr.wr_returned_date_sk,
         wr.wr_item_sk,
         -wr.wr_net_loss,
         -wr.wr_return_quantity,
         'web'
  FROM web_returns wr
),
combined AS (
  SELECT * FROM sales
  UNION ALL
  SELECT * FROM returns
)
SELECT d.d_year,
       i.i_category,
       c.channel,
       SUM(c.quantity) AS total_quantity,
       SUM(c.profit) AS total_profit
FROM combined c
JOIN date_dim d ON c.date_sk = d.d_date_sk
JOIN item i ON c.item_sk = i.i_item_sk
GROUP BY d.d_year, i.i_category, c.channel
ORDER BY d.d_year, i.i_category, c.channel
