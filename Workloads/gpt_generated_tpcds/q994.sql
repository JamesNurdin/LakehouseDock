WITH sales_transactions AS (
  SELECT
    CAST(date_trunc('month', d.d_date) AS DATE) AS sale_month,
    i.i_category,
    ss.ss_net_profit AS profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  UNION ALL
  SELECT
    CAST(date_trunc('month', d.d_date) AS DATE) AS sale_month,
    i.i_category,
    ws.ws_net_profit AS profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  UNION ALL
  SELECT
    CAST(date_trunc('month', d.d_date) AS DATE) AS sale_month,
    i.i_category,
    cs.cs_net_profit AS profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
),
return_transactions AS (
  SELECT
    CAST(date_trunc('month', d.d_date) AS DATE) AS sale_month,
    i.i_category,
    -sr.sr_net_loss AS profit
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  UNION ALL
  SELECT
    CAST(date_trunc('month', d.d_date) AS DATE) AS sale_month,
    i.i_category,
    -wr.wr_net_loss AS profit
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
)
SELECT
  t.sale_month,
  t.i_category,
  SUM(t.profit) AS net_profit,
  COUNT(*) AS transaction_count
FROM (
  SELECT * FROM sales_transactions
  UNION ALL
  SELECT * FROM return_transactions
) t
WHERE t.sale_month >= DATE '2020-01-01' AND t.sale_month < DATE '2022-01-01'
GROUP BY t.sale_month, t.i_category
ORDER BY net_profit DESC
LIMIT 10
