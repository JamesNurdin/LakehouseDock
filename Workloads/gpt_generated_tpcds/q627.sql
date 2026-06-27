WITH
    /* Store channel – sales */
    store_sales_agg AS (
        SELECT
            i.i_category               AS i_category,
            d.d_year                   AS d_year,
            d.d_month_seq              AS d_month_seq,
            SUM(ss.ss_net_profit)     AS net_profit,
            CAST(0 AS decimal(7,2))   AS net_loss
        FROM store_sales ss
        JOIN date_dim d   ON ss.ss_sold_date_sk   = d.d_date_sk
        JOIN item i       ON ss.ss_item_sk        = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY i.i_category, d.d_year, d.d_month_seq
    ),
    /* Store channel – returns */
    store_returns_agg AS (
        SELECT
            i.i_category               AS i_category,
            d.d_year                   AS d_year,
            d.d_month_seq              AS d_month_seq,
            CAST(0 AS decimal(7,2))   AS net_profit,
            SUM(sr.sr_net_loss)       AS net_loss
        FROM store_returns sr
        JOIN date_dim d   ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i       ON sr.sr_item_sk          = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY i.i_category, d.d_year, d.d_month_seq
    ),
    /* Catalog channel – sales */
    catalog_sales_agg AS (
        SELECT
            i.i_category               AS i_category,
            d.d_year                   AS d_year,
            d.d_month_seq              AS d_month_seq,
            SUM(cs.cs_net_profit)     AS net_profit,
            CAST(0 AS decimal(7,2))   AS net_loss
        FROM catalog_sales cs
        JOIN date_dim d   ON cs.cs_sold_date_sk   = d.d_date_sk
        JOIN item i       ON cs.cs_item_sk        = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY i.i_category, d.d_year, d.d_month_seq
    ),
    /* Catalog channel – returns */
    catalog_returns_agg AS (
        SELECT
            i.i_category               AS i_category,
            d.d_year                   AS d_year,
            d.d_month_seq              AS d_month_seq,
            CAST(0 AS decimal(7,2))   AS net_profit,
            SUM(cr.cr_net_loss)       AS net_loss
        FROM catalog_returns cr
        JOIN date_dim d   ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i       ON cr.cr_item_sk          = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY i.i_category, d.d_year, d.d_month_seq
    ),
    /* Web channel – sales */
    web_sales_agg AS (
        SELECT
            i.i_category               AS i_category,
            d.d_year                   AS d_year,
            d.d_month_seq              AS d_month_seq,
            SUM(ws.ws_net_profit)     AS net_profit,
            CAST(0 AS decimal(7,2))   AS net_loss
        FROM web_sales ws
        JOIN date_dim d   ON ws.ws_sold_date_sk   = d.d_date_sk
        JOIN item i       ON ws.ws_item_sk        = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY i.i_category, d.d_year, d.d_month_seq
    ),
    /* Web channel – returns */
    web_returns_agg AS (
        SELECT
            i.i_category               AS i_category,
            d.d_year                   AS d_year,
            d.d_month_seq              AS d_month_seq,
            CAST(0 AS decimal(7,2))   AS net_profit,
            SUM(wr.wr_net_loss)       AS net_loss
        FROM web_returns wr
        JOIN date_dim d   ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN item i       ON wr.wr_item_sk          = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY i.i_category, d.d_year, d.d_month_seq
    ),
    /* Combine all channels */
    combined AS (
        SELECT i_category, d_year, d_month_seq, net_profit, net_loss FROM store_sales_agg
        UNION ALL
        SELECT i_category, d_year, d_month_seq, net_profit, net_loss FROM store_returns_agg
        UNION ALL
        SELECT i_category, d_year, d_month_seq, net_profit, net_loss FROM catalog_sales_agg
        UNION ALL
        SELECT i_category, d_year, d_month_seq, net_profit, net_loss FROM catalog_returns_agg
        UNION ALL
        SELECT i_category, d_year, d_month_seq, net_profit, net_loss FROM web_sales_agg
        UNION ALL
        SELECT i_category, d_year, d_month_seq, net_profit, net_loss FROM web_returns_agg
    )
SELECT
    i_category,
    d_year,
    d_month_seq,
    SUM(net_profit) - SUM(net_loss) AS net_profit_after_returns
FROM combined
GROUP BY i_category, d_year, d_month_seq
ORDER BY d_year, d_month_seq, net_profit_after_returns DESC
LIMIT 20
