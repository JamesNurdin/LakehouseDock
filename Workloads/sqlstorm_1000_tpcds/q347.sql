WITH store_sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    date_trunc('month', d.d_date) AS month_date,
    i.i_category,
    'store' AS channel,
    SUM(ss.ss_net_profit) AS sales_net_profit,
    SUM(ss.ss_net_paid) AS sales_net_paid
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, date_trunc('month', d.d_date), i.i_category
),
web_sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    date_trunc('month', d.d_date) AS month_date,
    i.i_category,
    'web' AS channel,
    SUM(ws.ws_net_profit) AS sales_net_profit,
    SUM(ws.ws_net_paid) AS sales_net_paid
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, date_trunc('month', d.d_date), i.i_category
),
catalog_sales_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    date_trunc('month', d.d_date) AS month_date,
    i.i_category,
    'catalog' AS channel,
    SUM(cs.cs_net_profit) AS sales_net_profit,
    SUM(cs.cs_net_paid) AS sales_net_paid
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, date_trunc('month', d.d_date), i.i_category
),
store_returns_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    date_trunc('month', d.d_date) AS month_date,
    i.i_category,
    SUM(sr.sr_net_loss) AS returns_net_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, date_trunc('month', d.d_date), i.i_category
),
web_returns_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    date_trunc('month', d.d_date) AS month_date,
    i.i_category,
    SUM(wr.wr_net_loss) AS returns_net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, date_trunc('month', d.d_date), i.i_category
),
catalog_returns_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    date_trunc('month', d.d_date) AS month_date,
    i.i_category,
    SUM(cr.cr_net_loss) AS returns_net_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  GROUP BY d.d_year, d.d_month_seq, date_trunc('month', d.d_date), i.i_category
),
sales_combined AS (
  SELECT * FROM store_sales_agg
  UNION ALL
  SELECT * FROM web_sales_agg
  UNION ALL
  SELECT * FROM catalog_sales_agg
),
returns_combined AS (
  SELECT * FROM store_returns_agg
  UNION ALL
  SELECT * FROM web_returns_agg
  UNION ALL
  SELECT * FROM catalog_returns_agg
),
monthly_net AS (
  SELECT
    s.d_year,
    s.d_month_seq,
    s.month_date,
    s.i_category,
    s.channel,
    s.sales_net_profit,
    s.sales_net_paid,
    COALESCE(r.returns_net_loss, 0) AS returns_net_loss,
    s.sales_net_profit - COALESCE(r.returns_net_loss, 0) AS net_profit_adj,
    s.sales_net_paid - COALESCE(r.returns_net_loss, 0) AS net_paid_adj
  FROM sales_combined s
  LEFT JOIN returns_combined r
    ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.month_date = r.month_date
    AND s.i_category = r.i_category
)
SELECT
  m.d_year,
  m.d_month_seq,
  m.month_date,
  m.i_category,
  m.channel,
  m.net_profit_adj,
  m.net_paid_adj,
  RANK() OVER (PARTITION BY m.d_year, m.d_month_seq, m.channel ORDER BY m.net_profit_adj DESC) AS profit_rank,
  SUM(m.net_profit_adj) OVER (PARTITION BY m.channel, m.i_category ORDER BY m.month_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS profit_3_month_window
FROM monthly_net m
WHERE m.d_year >= 1998
ORDER BY m.d_year, m.d_month_seq, m.channel, m.net_profit_adj DESC
LIMIT 100
