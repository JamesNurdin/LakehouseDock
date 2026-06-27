WITH
    catalog_sales_monthly AS (
        SELECT d.d_year AS year,
               d.d_moy  AS month,
               SUM(cs.cs_net_profit) AS sales_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, d.d_moy
    ),
    catalog_returns_monthly AS (
        SELECT d.d_year AS year,
               d.d_moy  AS month,
               SUM(cr.cr_net_loss) AS returns_loss
        FROM catalog_returns cr
        JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
                              AND cr.cr_item_sk = cs.cs_item_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, d.d_moy
    ),
    store_sales_monthly AS (
        SELECT d.d_year AS year,
               d.d_moy  AS month,
               SUM(ss.ss_net_profit) AS sales_profit
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, d.d_moy
    ),
    store_returns_monthly AS (
        SELECT d.d_year AS year,
               d.d_moy  AS month,
               SUM(sr.sr_net_loss) AS returns_loss
        FROM store_returns sr
        JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
                             AND sr.sr_item_sk = ss.ss_item_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, d.d_moy
    ),
    web_sales_monthly AS (
        SELECT d.d_year AS year,
               d.d_moy  AS month,
               SUM(ws.ws_net_profit) AS sales_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, d.d_moy
    ),
    web_returns_monthly AS (
        SELECT d.d_year AS year,
               d.d_moy  AS month,
               SUM(wr.wr_net_loss) AS returns_loss
        FROM web_returns wr
        JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                           AND wr.wr_item_sk = ws.ws_item_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, d.d_moy
    ),
    catalog_combined AS (
        SELECT COALESCE(cs.year, cr.year)      AS year,
               COALESCE(cs.month, cr.month)    AS month,
               'catalog'                        AS channel,
               COALESCE(cs.sales_profit, 0) - COALESCE(cr.returns_loss, 0) AS net_profit
        FROM catalog_sales_monthly cs
        FULL OUTER JOIN catalog_returns_monthly cr
            ON cs.year = cr.year AND cs.month = cr.month
    ),
    store_combined AS (
        SELECT COALESCE(ss.year, sr.year)      AS year,
               COALESCE(ss.month, sr.month)    AS month,
               'store'                          AS channel,
               COALESCE(ss.sales_profit, 0) - COALESCE(sr.returns_loss, 0) AS net_profit
        FROM store_sales_monthly ss
        FULL OUTER JOIN store_returns_monthly sr
            ON ss.year = sr.year AND ss.month = sr.month
    ),
    web_combined AS (
        SELECT COALESCE(ws.year, wr.year)      AS year,
               COALESCE(ws.month, wr.month)    AS month,
               'web'                            AS channel,
               COALESCE(ws.sales_profit, 0) - COALESCE(wr.returns_loss, 0) AS net_profit
        FROM web_sales_monthly ws
        FULL OUTER JOIN web_returns_monthly wr
            ON ws.year = wr.year AND ws.month = wr.month
    )
SELECT year,
       month,
       channel,
       net_profit
FROM (
    SELECT year,
           month,
           channel,
           net_profit
    FROM catalog_combined
    UNION ALL
    SELECT year,
           month,
           channel,
           net_profit
    FROM store_combined
    UNION ALL
    SELECT year,
           month,
           channel,
           net_profit
    FROM web_combined
) AS combined
ORDER BY year,
         month,
         channel
