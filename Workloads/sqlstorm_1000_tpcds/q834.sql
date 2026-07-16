WITH catalog AS (
  SELECT d.d_year,
         i.i_category,
         SUM(cs.cs_ext_sales_price) AS gross_sales,
         SUM(cs.cs_net_profit) AS net_profit,
         COALESCE(SUM(cr.cr_net_loss), 0) AS net_loss
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
  WHERE d.d_year = 2001
  GROUP BY d.d_year, i.i_category
),
store AS (
  SELECT d.d_year,
         i.i_category,
         SUM(ss.ss_ext_sales_price) AS gross_sales,
         SUM(ss.ss_net_profit) AS net_profit,
         COALESCE(SUM(sr.sr_net_loss), 0) AS net_loss
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
  WHERE d.d_year = 2001
  GROUP BY d.d_year, i.i_category
),
web AS (
  SELECT d.d_year,
         i.i_category,
         SUM(ws.ws_ext_sales_price) AS gross_sales,
         SUM(ws.ws_net_profit) AS net_profit,
         COALESCE(SUM(wr.wr_net_loss), 0) AS net_loss
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
  WHERE d.d_year = 2001
  GROUP BY d.d_year, i.i_category
)
SELECT channel,
       d_year,
       i_category,
       SUM(gross_sales) AS total_gross_sales,
       SUM(net_profit) - SUM(net_loss) AS total_net_profit
FROM (
  SELECT 'catalog' AS channel, d_year, i_category, gross_sales, net_profit, net_loss FROM catalog
  UNION ALL
  SELECT 'store' AS channel, d_year, i_category, gross_sales, net_profit, net_loss FROM store
  UNION ALL
  SELECT 'web' AS channel, d_year, i_category, gross_sales, net_profit, net_loss FROM web
) t
GROUP BY channel, d_year, i_category
ORDER BY channel, total_net_profit DESC
LIMIT 100
