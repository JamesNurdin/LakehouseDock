WITH sales_agg AS (
  SELECT d.d_year,
         i.i_category,
         i.i_class,
         i.i_brand,
         SUM(cs.cs_net_paid) AS net_paid,
         SUM(cs.cs_net_profit) AS net_profit,
         'catalog' AS channel
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand
  UNION ALL
  SELECT d.d_year,
         i.i_category,
         i.i_class,
         i.i_brand,
         SUM(ss.ss_net_paid) AS net_paid,
         SUM(ss.ss_net_profit) AS net_profit,
         'store' AS channel
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand
  UNION ALL
  SELECT d.d_year,
         i.i_category,
         i.i_class,
         i.i_brand,
         SUM(ws.ws_net_paid) AS net_paid,
         SUM(ws.ws_net_profit) AS net_profit,
         'web' AS channel
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand
),
returns_agg AS (
  SELECT d.d_year,
         i.i_category,
         i.i_class,
         i.i_brand,
         SUM(cr.cr_return_amount) AS return_amount,
         'catalog' AS channel
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand
  UNION ALL
  SELECT d.d_year,
         i.i_category,
         i.i_class,
         i.i_brand,
         SUM(sr.sr_return_amt) AS return_amount,
         'store' AS channel
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand
  UNION ALL
  SELECT d.d_year,
         i.i_category,
         i.i_class,
         i.i_brand,
         SUM(wr.wr_return_amt) AS return_amount,
         'web' AS channel
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category, i.i_class, i.i_brand
)
SELECT s.d_year,
       s.i_category,
       s.i_class,
       s.i_brand,
       s.channel,
       s.net_paid,
       s.net_profit,
       COALESCE(r.return_amount, 0) AS total_return_amount,
       s.net_profit - COALESCE(r.return_amount, 0) AS net_profit_after_returns,
       (s.net_profit - COALESCE(r.return_amount, 0)) / NULLIF(s.net_paid, 0) AS profit_margin
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.d_year = r.d_year
 AND s.i_category = r.i_category
 AND s.i_class = r.i_class
 AND s.i_brand = r.i_brand
 AND s.channel = r.channel
WHERE s.d_year >= 2000
ORDER BY s.d_year DESC, net_profit_after_returns DESC
LIMIT 100
