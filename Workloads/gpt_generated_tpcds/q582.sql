/* Monthly net profit and loss across catalog, store, and web channels for the year 2001 */
WITH
    catalog_sales_agg AS (
        SELECT
            year(d.d_date)   AS year,
            month(d.d_date)  AS month,
            SUM(cs.cs_net_profit) AS catalog_net_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_date >= DATE '2001-01-01'
          AND d.d_date <  DATE '2002-01-01'
        GROUP BY year(d.d_date), month(d.d_date)
    ),
    catalog_returns_agg AS (
        SELECT
            year(d.d_date)   AS year,
            month(d.d_date)  AS month,
            SUM(cr.cr_net_loss) AS catalog_net_loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_date >= DATE '2001-01-01'
          AND d.d_date <  DATE '2002-01-01'
        GROUP BY year(d.d_date), month(d.d_date)
    ),
    store_sales_agg AS (
        SELECT
            year(d.d_date)   AS year,
            month(d.d_date)  AS month,
            SUM(ss.ss_net_profit) AS store_net_profit
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_date >= DATE '2001-01-01'
          AND d.d_date <  DATE '2002-01-01'
        GROUP BY year(d.d_date), month(d.d_date)
    ),
    store_returns_agg AS (
        SELECT
            year(d.d_date)   AS year,
            month(d.d_date)  AS month,
            SUM(sr.sr_net_loss) AS store_net_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_date >= DATE '2001-01-01'
          AND d.d_date <  DATE '2002-01-01'
        GROUP BY year(d.d_date), month(d.d_date)
    ),
    web_sales_agg AS (
        SELECT
            year(d.d_date)   AS year,
            month(d.d_date)  AS month,
            SUM(ws.ws_net_profit) AS web_net_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_date >= DATE '2001-01-01'
          AND d.d_date <  DATE '2002-01-01'
        GROUP BY year(d.d_date), month(d.d_date)
    ),
    web_returns_agg AS (
        SELECT
            year(d.d_date)   AS year,
            month(d.d_date)  AS month,
            SUM(wr.wr_net_loss) AS web_net_loss
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        WHERE d.d_date >= DATE '2001-01-01'
          AND d.d_date <  DATE '2002-01-01'
        GROUP BY year(d.d_date), month(d.d_date)
    ),
    combined AS (
        SELECT
            COALESCE(cs.year, cr.year, ss.year, sr.year, ws.year, wr.year) AS year,
            COALESCE(cs.month, cr.month, ss.month, sr.month, ws.month, wr.month) AS month,
            COALESCE(cs.catalog_net_profit, 0) AS catalog_net_profit,
            COALESCE(cr.catalog_net_loss,   0) AS catalog_net_loss,
            COALESCE(ss.store_net_profit,   0) AS store_net_profit,
            COALESCE(sr.store_net_loss,     0) AS store_net_loss,
            COALESCE(ws.web_net_profit,     0) AS web_net_profit,
            COALESCE(wr.web_net_loss,       0) AS web_net_loss
        FROM catalog_sales_agg   cs
        FULL OUTER JOIN catalog_returns_agg cr ON cs.year = cr.year AND cs.month = cr.month
        FULL OUTER JOIN store_sales_agg    ss ON COALESCE(cs.year, cr.year) = ss.year
                                            AND COALESCE(cs.month, cr.month) = ss.month
        FULL OUTER JOIN store_returns_agg  sr ON COALESCE(cs.year, cr.year, ss.year) = sr.year
                                            AND COALESCE(cs.month, cr.month, ss.month) = sr.month
        FULL OUTER JOIN web_sales_agg      ws ON COALESCE(cs.year, cr.year, ss.year, sr.year) = ws.year
                                            AND COALESCE(cs.month, cr.month, ss.month, sr.month) = ws.month
        FULL OUTER JOIN web_returns_agg    wr ON COALESCE(cs.year, cr.year, ss.year, sr.year, ws.year) = wr.year
                                            AND COALESCE(cs.month, cr.month, ss.month, sr.month, ws.month) = wr.month
    )
SELECT
    year,
    month,
    catalog_net_profit,
    catalog_net_loss,
    store_net_profit,
    store_net_loss,
    web_net_profit,
    web_net_loss,
    (catalog_net_profit + store_net_profit + web_net_profit) -
    (catalog_net_loss   + store_net_loss   + web_net_loss)   AS net_result,
    (catalog_net_loss + store_net_loss + web_net_loss) /
    NULLIF((catalog_net_profit + store_net_profit + web_net_profit), 0) AS loss_ratio
FROM combined
ORDER BY year, month
