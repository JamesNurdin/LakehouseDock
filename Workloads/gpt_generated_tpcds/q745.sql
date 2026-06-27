WITH date_ym AS (
       SELECT DISTINCT d.d_year,
                       d.d_moy
       FROM   date_dim d
       WHERE  d.d_year = 2001
   ),
   store_sales_agg AS (
       SELECT d.d_year,
              d.d_moy,
              SUM(ss.ss_net_profit) AS store_sales_profit
       FROM   store_sales ss
       JOIN   date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
       GROUP BY d.d_year, d.d_moy
   ),
   store_returns_agg AS (
       SELECT d.d_year,
              d.d_moy,
              SUM(sr.sr_net_loss) AS store_returns_loss
       FROM   store_returns sr
       JOIN   date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
       GROUP BY d.d_year, d.d_moy
   ),
   catalog_sales_agg AS (
       SELECT d.d_year,
              d.d_moy,
              SUM(cs.cs_net_profit) AS catalog_sales_profit
       FROM   catalog_sales cs
       JOIN   date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
       GROUP BY d.d_year, d.d_moy
   ),
   catalog_returns_agg AS (
       SELECT d.d_year,
              d.d_moy,
              SUM(cr.cr_net_loss) AS catalog_returns_loss
       FROM   catalog_returns cr
       JOIN   date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
       GROUP BY d.d_year, d.d_moy
   ),
   web_sales_agg AS (
       SELECT d.d_year,
              d.d_moy,
              SUM(ws.ws_net_profit) AS web_sales_profit
       FROM   web_sales ws
       JOIN   date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
       GROUP BY d.d_year, d.d_moy
   ),
   web_returns_agg AS (
       SELECT d.d_year,
              d.d_moy,
              SUM(wr.wr_net_loss) AS web_returns_loss
       FROM   web_returns wr
       JOIN   date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
       GROUP BY d.d_year, d.d_moy
   )
SELECT dym.d_year,
       dym.d_moy,
       COALESCE(ssa.store_sales_profit, 0)      AS store_sales_profit,
       COALESCE(sra.store_returns_loss, 0)      AS store_returns_loss,
       COALESCE(csa.catalog_sales_profit, 0)    AS catalog_sales_profit,
       COALESCE(cra.catalog_returns_loss, 0)    AS catalog_returns_loss,
       COALESCE(wsa.web_sales_profit, 0)       AS web_sales_profit,
       COALESCE(wra.web_returns_loss, 0)       AS web_returns_loss,
       (COALESCE(ssa.store_sales_profit, 0) + COALESCE(csa.catalog_sales_profit, 0) + COALESCE(wsa.web_sales_profit, 0))
       - (COALESCE(sra.store_returns_loss, 0) + COALESCE(cra.catalog_returns_loss, 0) + COALESCE(wra.web_returns_loss, 0))
         AS net_profit_after_returns
FROM   date_ym dym
LEFT JOIN store_sales_agg   ssa ON dym.d_year = ssa.d_year AND dym.d_moy = ssa.d_moy
LEFT JOIN store_returns_agg sra ON dym.d_year = sra.d_year AND dym.d_moy = sra.d_moy
LEFT JOIN catalog_sales_agg csa ON dym.d_year = csa.d_year AND dym.d_moy = csa.d_moy
LEFT JOIN catalog_returns_agg cra ON dym.d_year = cra.d_year AND dym.d_moy = cra.d_moy
LEFT JOIN web_sales_agg    wsa ON dym.d_year = wsa.d_year AND dym.d_moy = wsa.d_moy
LEFT JOIN web_returns_agg  wra ON dym.d_year = wra.d_year AND dym.d_moy = wra.d_moy
ORDER BY dym.d_year, dym.d_moy
