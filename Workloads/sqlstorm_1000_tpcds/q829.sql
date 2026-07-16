WITH all_sales AS (
  SELECT ss.ss_sold_date_sk AS sold_date_sk,
         i.i_category AS category,
         ss.ss_net_profit AS net_profit,
         ss.ss_quantity AS quantity,
         'store' AS channel
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  UNION ALL
  SELECT cs.cs_sold_date_sk,
         i.i_category,
         cs.cs_net_profit,
         cs.cs_quantity,
         'catalog'
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         i.i_category,
         ws.ws_net_profit,
         ws.ws_quantity,
         'web'
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
sales_summary AS (
  SELECT d.d_year AS year,
         s.category,
         s.channel,
         SUM(s.net_profit) AS total_net_profit,
         SUM(s.quantity) AS total_quantity_sold
  FROM all_sales s
  JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
  GROUP BY d.d_year, s.category, s.channel
),
all_returns AS (
  SELECT sr.sr_returned_date_sk AS returned_date_sk,
         i.i_category AS category,
         sr.sr_net_loss AS net_loss,
         sr.sr_return_quantity AS quantity,
         'store' AS channel
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  UNION ALL
  SELECT cr.cr_returned_date_sk,
         i.i_category,
         cr.cr_net_loss,
         cr.cr_return_quantity,
         'catalog'
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  UNION ALL
  SELECT wr.wr_returned_date_sk,
         i.i_category,
         wr.wr_net_loss,
         wr.wr_return_quantity,
         'web'
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
returns_summary AS (
  SELECT d.d_year AS year,
         r.category,
         r.channel,
         SUM(r.net_loss) AS total_net_loss,
         SUM(r.quantity) AS total_quantity_returned
  FROM all_returns r
  JOIN date_dim d ON r.returned_date_sk = d.d_date_sk
  GROUP BY d.d_year, r.category, r.channel
)
SELECT
  ss.year,
  ss.category,
  ss.channel,
  ss.total_net_profit,
  COALESCE(rs.total_net_loss, 0) AS total_net_loss,
  ss.total_net_profit - COALESCE(rs.total_net_loss, 0) AS net_margin,
  ss.total_quantity_sold,
  COALESCE(rs.total_quantity_returned, 0) AS total_quantity_returned
FROM sales_summary ss
LEFT JOIN returns_summary rs
  ON ss.year = rs.year
 AND ss.category = rs.category
 AND ss.channel = rs.channel
ORDER BY ss.year, ss.category, ss.channel
