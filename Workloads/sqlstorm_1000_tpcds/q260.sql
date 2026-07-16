WITH
cat_sales AS (
 SELECT d.d_year,
        sum(cs.cs_net_profit) AS sales_profit
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 GROUP BY d.d_year
),
cat_returns AS (
 SELECT d.d_year,
        sum(cr.cr_net_loss) AS return_loss
 FROM catalog_returns cr
 JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
 GROUP BY d.d_year
),
store_sales AS (
 SELECT d.d_year,
        sum(ss.ss_net_profit) AS sales_profit
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 GROUP BY d.d_year
),
store_returns AS (
 SELECT d.d_year,
        sum(sr.sr_net_loss) AS return_loss
 FROM store_returns sr
 JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
 GROUP BY d.d_year
),
web_sales AS (
 SELECT d.d_year,
        sum(ws.ws_net_profit) AS sales_profit
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 GROUP BY d.d_year
),
web_returns AS (
 SELECT d.d_year,
        sum(wr.wr_net_loss) AS return_loss
 FROM web_returns wr
 JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
 GROUP BY d.d_year
)
SELECT coalesce(cs.d_year, cr.d_year, ss.d_year, sr.d_year, ws.d_year, wr.d_year) AS year,
       coalesce(cs.sales_profit, 0) - coalesce(cr.return_loss, 0) AS net_catalog_profit,
       coalesce(ss.sales_profit, 0) - coalesce(sr.return_loss, 0) AS net_store_profit,
       coalesce(ws.sales_profit, 0) - coalesce(wr.return_loss, 0) AS net_web_profit,
       (coalesce(cs.sales_profit, 0) - coalesce(cr.return_loss, 0)
        + coalesce(ss.sales_profit, 0) - coalesce(sr.return_loss, 0)
        + coalesce(ws.sales_profit, 0) - coalesce(wr.return_loss, 0)) AS total_net_profit
FROM cat_sales cs
FULL OUTER JOIN cat_returns cr ON cs.d_year = cr.d_year
FULL OUTER JOIN store_sales ss ON coalesce(cs.d_year, cr.d_year) = ss.d_year
FULL OUTER JOIN store_returns sr ON coalesce(cs.d_year, cr.d_year, ss.d_year) = sr.d_year
FULL OUTER JOIN web_sales ws ON coalesce(cs.d_year, cr.d_year, ss.d_year, sr.d_year) = ws.d_year
FULL OUTER JOIN web_returns wr ON coalesce(cs.d_year, cr.d_year, ss.d_year, sr.d_year, ws.d_year) = wr.d_year
ORDER BY year
