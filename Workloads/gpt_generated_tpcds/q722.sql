WITH
    store_profit AS (
        SELECT d.d_year AS year,
               SUM(ss.ss_net_profit) AS net_profit
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        GROUP BY d.d_year
    ),
    catalog_profit AS (
        SELECT d.d_year AS year,
               SUM(cs.cs_net_profit) AS net_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        GROUP BY d.d_year
    ),
    catalog_loss AS (
        SELECT d.d_year AS year,
               SUM(cr.cr_net_loss) AS return_loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        GROUP BY d.d_year
    ),
    web_profit AS (
        SELECT d.d_year AS year,
               SUM(ws.ws_net_profit) AS net_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        GROUP BY d.d_year
    ),
    web_loss AS (
        SELECT d.d_year AS year,
               SUM(wr.wr_net_loss) AS return_loss
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        GROUP BY d.d_year
    ),
    catalog_combined AS (
        SELECT cp.year,
               cp.net_profit,
               COALESCE(cl.return_loss, 0) AS return_loss,
               cp.net_profit - COALESCE(cl.return_loss, 0) AS net_profit_after_returns
        FROM catalog_profit cp
        LEFT JOIN catalog_loss cl ON cp.year = cl.year
    ),
    web_combined AS (
        SELECT wp.year,
               wp.net_profit,
               COALESCE(wl.return_loss, 0) AS return_loss,
               wp.net_profit - COALESCE(wl.return_loss, 0) AS net_profit_after_returns
        FROM web_profit wp
        LEFT JOIN web_loss wl ON wp.year = wl.year
    ),
    store_combined AS (
        SELECT sp.year,
               sp.net_profit,
               0 AS return_loss,
               sp.net_profit AS net_profit_after_returns
        FROM store_profit sp
    )
SELECT year,
       'Store'   AS channel,
       net_profit,
       return_loss,
       net_profit_after_returns
FROM   store_combined
UNION ALL
SELECT year,
       'Catalog' AS channel,
       net_profit,
       return_loss,
       net_profit_after_returns
FROM   catalog_combined
UNION ALL
SELECT year,
       'Web'     AS channel,
       net_profit,
       return_loss,
       net_profit_after_returns
FROM   web_combined
ORDER BY year,
         channel
