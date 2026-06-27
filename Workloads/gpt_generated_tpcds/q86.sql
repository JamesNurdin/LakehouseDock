WITH sales AS (
  SELECT i.i_category AS i_category,
         d.d_year AS d_year,
         'store' AS channel,
         SUM(ss.ss_net_profit) AS net_profit,
         0.0 AS net_loss
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
  GROUP BY i.i_category, d.d_year

  UNION ALL

  SELECT i.i_category,
         d.d_year,
         'catalog' AS channel,
         SUM(cs.cs_net_profit) AS net_profit,
         0.0 AS net_loss
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
  GROUP BY i.i_category, d.d_year

  UNION ALL

  SELECT i.i_category,
         d.d_year,
         'web' AS channel,
         SUM(ws.ws_net_profit) AS net_profit,
         0.0 AS net_loss
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
  GROUP BY i.i_category, d.d_year
),
returns AS (
  SELECT i.i_category AS i_category,
         d.d_year AS d_year,
         'store' AS channel,
         0.0 AS net_profit,
         SUM(sr.sr_net_loss) AS net_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
  GROUP BY i.i_category, d.d_year

  UNION ALL

  SELECT i.i_category,
         d.d_year,
         'catalog' AS channel,
         0.0 AS net_profit,
         SUM(cr.cr_net_loss) AS net_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
  GROUP BY i.i_category, d.d_year

  UNION ALL

  SELECT i.i_category,
         d.d_year,
         'web' AS channel,
         0.0 AS net_profit,
         SUM(wr.wr_net_loss) AS net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
  GROUP BY i.i_category, d.d_year
)
SELECT s.i_category,
       s.d_year,
       s.channel,
       s.net_profit,
       COALESCE(r.net_loss, 0.0) AS net_loss,
       s.net_profit - COALESCE(r.net_loss, 0.0) AS net_contribution
FROM sales s
LEFT JOIN returns r
  ON s.i_category = r.i_category
 AND s.d_year = r.d_year
 AND s.channel = r.channel
ORDER BY s.i_category, s.d_year, s.channel
