WITH store_sales_agg AS (
  SELECT ss.ss_sold_date_sk AS date_sk,
         ss.ss_store_sk AS store_sk,
         ss.ss_item_sk AS item_sk,
         SUM(ss.ss_quantity) AS quantity_sold,
         SUM(ss.ss_net_paid) AS sales_amount,
         SUM(ss.ss_net_profit) AS profit_amount
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2001
  GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk, ss.ss_item_sk
),
catalog_sales_agg AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_item_sk AS item_sk,
         SUM(cs.cs_quantity) AS quantity_sold,
         SUM(cs.cs_net_paid) AS sales_amount,
         SUM(cs.cs_net_profit) AS profit_amount
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2001
  GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk
),
web_sales_agg AS (
  SELECT ws.ws_sold_date_sk AS date_sk,
         ws.ws_item_sk AS item_sk,
         SUM(ws.ws_quantity) AS quantity_sold,
         SUM(ws.ws_net_paid) AS sales_amount,
         SUM(ws.ws_net_profit) AS profit_amount
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2001
  GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
store_returns_agg AS (
  SELECT sr.sr_returned_date_sk AS date_sk,
         sr.sr_store_sk AS store_sk,
         sr.sr_item_sk AS item_sk,
         SUM(sr.sr_return_quantity) AS qty_returned,
         SUM(sr.sr_return_amt) AS return_amount,
         SUM(sr.sr_net_loss) AS return_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2001
  GROUP BY sr.sr_returned_date_sk, sr.sr_store_sk, sr.sr_item_sk
),
catalog_returns_agg AS (
  SELECT cr.cr_returned_date_sk AS date_sk,
         cr.cr_item_sk AS item_sk,
         SUM(cr.cr_return_quantity) AS qty_returned,
         SUM(cr.cr_return_amount) AS return_amount,
         SUM(cr.cr_net_loss) AS return_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2001
  GROUP BY cr.cr_returned_date_sk, cr.cr_item_sk
),
web_returns_agg AS (
  SELECT wr.wr_returned_date_sk AS date_sk,
         wr.wr_item_sk AS item_sk,
         SUM(wr.wr_return_quantity) AS qty_returned,
         SUM(wr.wr_return_amt) AS return_amount,
         SUM(wr.wr_net_loss) AS return_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2001
  GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk
),
combined AS (
  SELECT 'store' AS channel,
         ss.date_sk,
         ss.store_sk,
         ss.item_sk,
         ss.quantity_sold,
         ss.sales_amount,
         ss.profit_amount,
         COALESCE(sr.qty_returned, 0) AS qty_returned,
         COALESCE(sr.return_amount, 0) AS return_amount,
         COALESCE(sr.return_loss, 0) AS return_loss
  FROM store_sales_agg ss
  LEFT JOIN store_returns_agg sr
    ON ss.date_sk = sr.date_sk
   AND ss.store_sk = sr.store_sk
   AND ss.item_sk = sr.item_sk
  UNION ALL
  SELECT 'catalog' AS channel,
         cs.date_sk,
         NULL AS store_sk,
         cs.item_sk,
         cs.quantity_sold,
         cs.sales_amount,
         cs.profit_amount,
         COALESCE(cr.qty_returned, 0) AS qty_returned,
         COALESCE(cr.return_amount, 0) AS return_amount,
         COALESCE(cr.return_loss, 0) AS return_loss
  FROM catalog_sales_agg cs
  LEFT JOIN catalog_returns_agg cr
    ON cs.date_sk = cr.date_sk
   AND cs.item_sk = cr.item_sk
  UNION ALL
  SELECT 'web' AS channel,
         ws.date_sk,
         NULL AS store_sk,
         ws.item_sk,
         ws.quantity_sold,
         ws.sales_amount,
         ws.profit_amount,
         COALESCE(wr.qty_returned, 0) AS qty_returned,
         COALESCE(wr.return_amount, 0) AS return_amount,
         COALESCE(wr.return_loss, 0) AS return_loss
  FROM web_sales_agg ws
  LEFT JOIN web_returns_agg wr
    ON ws.date_sk = wr.date_sk
   AND ws.item_sk = wr.item_sk
),
aggregated AS (
  SELECT
    c.channel,
    d.d_year,
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    SUM(c.quantity_sold) AS total_quantity_sold,
    SUM(c.sales_amount) AS total_sales_amount,
    SUM(c.return_amount) AS total_return_amount,
    SUM(c.sales_amount - c.return_amount) AS net_revenue,
    SUM(c.profit_amount) AS total_profit,
    CASE WHEN SUM(c.sales_amount) = 0 THEN 0
         ELSE SUM(c.profit_amount) / SUM(c.sales_amount) END AS profit_margin
  FROM combined c
  JOIN date_dim d ON c.date_sk = d.d_date_sk
  LEFT JOIN store s ON c.store_sk = s.s_store_sk
  JOIN item i ON c.item_sk = i.i_item_sk
  GROUP BY c.channel, d.d_year, s.s_store_name, i.i_item_id, i.i_product_name
  HAVING SUM(c.sales_amount) > 0
)
SELECT
  a.channel,
  a.d_year,
  a.s_store_name,
  a.i_item_id,
  a.i_product_name,
  a.total_quantity_sold,
  a.total_sales_amount,
  a.total_return_amount,
  a.net_revenue,
  a.total_profit,
  a.profit_margin,
  RANK() OVER (PARTITION BY a.channel, a.d_year ORDER BY a.net_revenue DESC) AS revenue_rank
FROM aggregated a
ORDER BY a.channel, a.d_year, revenue_rank
LIMIT 100
