WITH
    store_sales_agg AS (
        SELECT
            i.i_category AS category,
            d.d_year AS year,
            'store' AS channel,
            SUM(ss.ss_net_profit) AS net_profit,
            0 AS net_loss
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        GROUP BY i.i_category, d.d_year
    ),
    store_returns_agg AS (
        SELECT
            i.i_category AS category,
            d.d_year AS year,
            'store' AS channel,
            0 AS net_profit,
            SUM(sr.sr_net_loss) AS net_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        GROUP BY i.i_category, d.d_year
    ),
    web_sales_agg AS (
        SELECT
            i.i_category AS category,
            d.d_year AS year,
            'web' AS channel,
            SUM(ws.ws_net_profit) AS net_profit,
            0 AS net_loss
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        GROUP BY i.i_category, d.d_year
    ),
    web_returns_agg AS (
        SELECT
            i.i_category AS category,
            d.d_year AS year,
            'web' AS channel,
            0 AS net_profit,
            SUM(wr.wr_net_loss) AS net_loss
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        GROUP BY i.i_category, d.d_year
    ),
    catalog_sales_agg AS (
        SELECT
            i.i_category AS category,
            d.d_year AS year,
            'catalog' AS channel,
            SUM(cs.cs_net_profit) AS net_profit,
            0 AS net_loss
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        GROUP BY i.i_category, d.d_year
    ),
    catalog_returns_agg AS (
        SELECT
            i.i_category AS category,
            d.d_year AS year,
            'catalog' AS channel,
            0 AS net_profit,
            SUM(cr.cr_net_loss) AS net_loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        GROUP BY i.i_category, d.d_year
    ),
    combined AS (
        SELECT category, year, channel, net_profit, net_loss FROM store_sales_agg
        UNION ALL
        SELECT category, year, channel, net_profit, net_loss FROM store_returns_agg
        UNION ALL
        SELECT category, year, channel, net_profit, net_loss FROM web_sales_agg
        UNION ALL
        SELECT category, year, channel, net_profit, net_loss FROM web_returns_agg
        UNION ALL
        SELECT category, year, channel, net_profit, net_loss FROM catalog_sales_agg
        UNION ALL
        SELECT category, year, channel, net_profit, net_loss FROM catalog_returns_agg
    )
SELECT
    channel,
    category,
    year,
    SUM(net_profit) AS total_net_profit,
    SUM(net_loss) AS total_net_loss,
    SUM(net_profit) - SUM(net_loss) AS net_margin,
    CASE
        WHEN (SUM(net_profit) + SUM(net_loss)) = 0 THEN NULL
        ELSE SUM(net_profit) / (SUM(net_profit) + SUM(net_loss))
    END AS net_profit_ratio
FROM combined
GROUP BY channel, category, year
ORDER BY channel, category, year
