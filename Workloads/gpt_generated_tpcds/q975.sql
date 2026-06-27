/* Net profit and net loss by year and sales channel (store, catalog, web) */
SELECT
    year,
    channel,
    total_net_profit,
    total_net_loss,
    total_net_profit - total_net_loss AS net_profit_after_returns
FROM (
    /* Store channel */
    SELECT
        d_sales.d_year AS year,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COALESCE((
            SELECT SUM(sr.sr_net_loss)
            FROM store_returns sr
            JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
            WHERE d_return.d_year = d_sales.d_year
        ), 0) AS total_net_loss
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    GROUP BY d_sales.d_year

    UNION ALL

    /* Catalog channel */
    SELECT
        d_sales.d_year AS year,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COALESCE((
            SELECT SUM(cr.cr_net_loss)
            FROM catalog_returns cr
            JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
            WHERE d_return.d_year = d_sales.d_year
        ), 0) AS total_net_loss
    FROM catalog_sales cs
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    GROUP BY d_sales.d_year

    UNION ALL

    /* Web channel */
    SELECT
        d_sales.d_year AS year,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COALESCE((
            SELECT SUM(wr.wr_net_loss)
            FROM web_returns wr
            JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
            WHERE d_return.d_year = d_sales.d_year
        ), 0) AS total_net_loss
    FROM web_sales ws
    JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
    GROUP BY d_sales.d_year
) AS agg
ORDER BY year, channel
