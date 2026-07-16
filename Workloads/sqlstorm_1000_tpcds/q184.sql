WITH store_sales_agg AS (
  SELECT d.d_year,
         d.d_month_seq,
         i.i_category,
         sum(ss.ss_net_profit) AS sales_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category
),
store_returns_agg AS (
  SELECT d.d_year,
         d.d_month_seq,
         i.i_category,
         sum(sr.sr_net_loss) AS returns_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_sales_agg AS (
  SELECT d.d_year,
         d.d_month_seq,
         i.i_category,
         sum(cs.cs_net_profit) AS sales_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_returns_agg AS (
  SELECT d.d_year,
         d.d_month_seq,
         i.i_category,
         sum(cr.cr_net_loss) AS returns_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_sales_agg AS (
  SELECT d.d_year,
         d.d_month_seq,
         i.i_category,
         sum(ws.ws_net_profit) AS sales_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_returns_agg AS (
  SELECT d.d_year,
         d.d_month_seq,
         i.i_category,
         sum(wr.wr_net_loss) AS returns_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, i.i_category
),
combined AS (
  SELECT s.d_year,
         s.d_month_seq,
         s.i_category,
         'Store' AS channel,
         coalesce(s.sales_profit, 0) - coalesce(r.returns_loss, 0) AS net_profit
  FROM store_sales_agg s
  LEFT JOIN store_returns_agg r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.i_category = r.i_category
  UNION ALL
  SELECT c.d_year,
         c.d_month_seq,
         c.i_category,
         'Catalog' AS channel,
         coalesce(c.sales_profit, 0) - coalesce(r.returns_loss, 0) AS net_profit
  FROM catalog_sales_agg c
  LEFT JOIN catalog_returns_agg r
    ON c.d_year = r.d_year
   AND c.d_month_seq = r.d_month_seq
   AND c.i_category = r.i_category
  UNION ALL
  SELECT w.d_year,
         w.d_month_seq,
         w.i_category,
         'Web' AS channel,
         coalesce(w.sales_profit, 0) - coalesce(r.returns_loss, 0) AS net_profit
  FROM web_sales_agg w
  LEFT JOIN web_returns_agg r
    ON w.d_year = r.d_year
   AND w.d_month_seq = r.d_month_seq
   AND w.i_category = r.i_category
)
SELECT d_year,
       d_month_seq,
       i_category,
       channel,
       net_profit,
       sum(net_profit) OVER (PARTITION BY channel ORDER BY d_year, d_month_seq) AS cumulative_profit,
       row_number() OVER (PARTITION BY d_year, d_month_seq ORDER BY net_profit DESC) AS rank
FROM combined
WHERE net_profit IS NOT NULL
ORDER BY d_year, d_month_seq, rank
LIMIT 200
