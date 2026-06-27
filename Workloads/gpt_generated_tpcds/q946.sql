WITH all_channel_net AS (
  SELECT i.i_category AS i_category,
         ss.ss_net_profit AS net_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year = 2000

  UNION ALL

  SELECT i.i_category AS i_category,
         -sr.sr_net_loss AS net_profit
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE d.d_year = 2000

  UNION ALL

  SELECT i.i_category AS i_category,
         cs.cs_net_profit AS net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year = 2000

  UNION ALL

  SELECT i.i_category AS i_category,
         -cr.cr_net_loss AS net_profit
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE d.d_year = 2000

  UNION ALL

  SELECT i.i_category AS i_category,
         ws.ws_net_profit AS net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year = 2000

  UNION ALL

  SELECT i.i_category AS i_category,
         -wr.wr_net_loss AS net_profit
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year = 2000
)
SELECT i_category,
       SUM(net_profit) AS net_profit_2000
FROM all_channel_net
GROUP BY i_category
ORDER BY net_profit_2000 DESC
LIMIT 10
