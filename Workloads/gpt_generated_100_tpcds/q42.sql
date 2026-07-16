WITH unified AS (
  -- Sales rows (profit only)
  SELECT i.i_category AS category,
         d.d_year AS year,
         ss.ss_net_profit AS net_profit,
         CAST(0.0 AS decimal(7,2)) AS return_loss
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk

  UNION ALL

  SELECT i.i_category,
         d.d_year,
         cs.cs_net_profit,
         CAST(0.0 AS decimal(7,2))
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk

  UNION ALL

  SELECT i.i_category,
         d.d_year,
         ws.ws_net_profit,
         CAST(0.0 AS decimal(7,2))
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk

  -- Return rows (loss only)
  UNION ALL

  SELECT i.i_category,
         dr.d_year,
         CAST(0.0 AS decimal(7,2)),
         cr.cr_net_loss
  FROM catalog_returns cr
  JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk

  UNION ALL

  SELECT i.i_category,
         dr.d_year,
         CAST(0.0 AS decimal(7,2)),
         sr.sr_net_loss
  FROM store_returns sr
  JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk

  UNION ALL

  SELECT i.i_category,
         dr.d_year,
         CAST(0.0 AS decimal(7,2)),
         wr.wr_net_loss
  FROM web_returns wr
  JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
)
SELECT category,
       year,
       SUM(net_profit) AS total_profit,
       SUM(return_loss) AS total_return_loss,
       SUM(net_profit) - SUM(return_loss) AS adjusted_profit
FROM unified
WHERE year = 2001
GROUP BY category, year
ORDER BY category
