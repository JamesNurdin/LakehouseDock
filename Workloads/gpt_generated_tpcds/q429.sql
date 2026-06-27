WITH channel_contributions AS (
  SELECT i.i_category AS category,
         SUM(ss.ss_net_profit) AS net_amount
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_category

  UNION ALL

  SELECT i.i_category AS category,
         -SUM(sr.sr_net_loss) AS net_amount
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_category

  UNION ALL

  SELECT i.i_category AS category,
         SUM(cs.cs_net_profit) AS net_amount
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_category

  UNION ALL

  SELECT i.i_category AS category,
         -SUM(cr.cr_net_loss) AS net_amount
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_category

  UNION ALL

  SELECT i.i_category AS category,
         SUM(ws.ws_net_profit) AS net_amount
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_category

  UNION ALL

  SELECT i.i_category AS category,
         -SUM(wr.wr_net_loss) AS net_amount
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY i.i_category
)
SELECT category,
       SUM(net_amount) AS total_net_profit
FROM channel_contributions
GROUP BY category
ORDER BY total_net_profit DESC
LIMIT 10
