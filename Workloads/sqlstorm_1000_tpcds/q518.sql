WITH
c_sales AS (
  SELECT d.d_year,
         i.i_category,
         SUM(cs.cs_net_profit) AS profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category
),
s_sales AS (
  SELECT d.d_year,
         i.i_category,
         SUM(ss.ss_net_profit) AS profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category
),
w_sales AS (
  SELECT d.d_year,
         i.i_category,
         SUM(ws.ws_net_profit) AS profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category
),
c_returns AS (
  SELECT d.d_year,
         i.i_category,
         SUM(cr.cr_net_loss) AS loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category
),
s_returns AS (
  SELECT d.d_year,
         i.i_category,
         SUM(sr.sr_net_loss) AS loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category
),
w_returns AS (
  SELECT d.d_year,
         i.i_category,
         SUM(wr.wr_net_loss) AS loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  GROUP BY d.d_year, i.i_category
)
SELECT
  COALESCE(c.d_year, s.d_year, w.d_year, cr.d_year, sr.d_year, wr.d_year) AS year,
  COALESCE(c.i_category, s.i_category, w.i_category, cr.i_category, sr.i_category, wr.i_category) AS category,
  COALESCE(c.profit, 0) AS catalog_profit,
  COALESCE(s.profit, 0) AS store_profit,
  COALESCE(w.profit, 0) AS web_profit,
  COALESCE(cr.loss, 0) AS catalog_loss,
  COALESCE(sr.loss, 0) AS store_loss,
  COALESCE(wr.loss, 0) AS web_loss,
  (COALESCE(c.profit, 0) + COALESCE(s.profit, 0) + COALESCE(w.profit, 0) - COALESCE(cr.loss, 0) - COALESCE(sr.loss, 0) - COALESCE(wr.loss, 0)) AS net_total
FROM c_sales c
FULL OUTER JOIN s_sales s ON c.d_year = s.d_year AND c.i_category = s.i_category
FULL OUTER JOIN w_sales w ON COALESCE(c.d_year, s.d_year) = w.d_year AND COALESCE(c.i_category, s.i_category) = w.i_category
FULL OUTER JOIN c_returns cr ON COALESCE(c.d_year, s.d_year, w.d_year) = cr.d_year AND COALESCE(c.i_category, s.i_category, w.i_category) = cr.i_category
FULL OUTER JOIN s_returns sr ON COALESCE(c.d_year, s.d_year, w.d_year, cr.d_year) = sr.d_year AND COALESCE(c.i_category, s.i_category, w.i_category, cr.i_category) = sr.i_category
FULL OUTER JOIN w_returns wr ON COALESCE(c.d_year, s.d_year, w.d_year, cr.d_year, sr.d_year) = wr.d_year AND COALESCE(c.i_category, s.i_category, w.i_category, cr.i_category, sr.i_category) = wr.i_category
ORDER BY year, category
LIMIT 100
