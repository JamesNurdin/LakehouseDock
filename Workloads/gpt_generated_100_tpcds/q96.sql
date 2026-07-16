WITH
    store_sales_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            i.i_category,
            SUM(ss.ss_net_profit) AS net_profit_store
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, d.d_month_seq, i.i_category
    ),
    store_returns_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            i.i_category,
            SUM(sr.sr_net_loss) AS net_loss_store
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, d.d_month_seq, i.i_category
    ),
    catalog_sales_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            i.i_category,
            SUM(cs.cs_net_profit) AS net_profit_catalog
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, d.d_month_seq, i.i_category
    ),
    catalog_returns_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            i.i_category,
            SUM(cr.cr_net_loss) AS net_loss_catalog
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, d.d_month_seq, i.i_category
    ),
    web_sales_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            i.i_category,
            SUM(ws.ws_net_profit) AS net_profit_web
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, d.d_month_seq, i.i_category
    ),
    web_returns_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            i.i_category,
            SUM(wr.wr_net_loss) AS net_loss_web
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, d.d_month_seq, i.i_category
    ),
    combined AS (
        SELECT
            COALESCE(ss.d_year, sr.d_year, cs.d_year, cr.d_year, ws.d_year, wr.d_year)   AS year,
            COALESCE(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq, cr.d_month_seq, ws.d_month_seq, wr.d_month_seq) AS month_seq,
            COALESCE(ss.i_category, sr.i_category, cs.i_category, cr.i_category, ws.i_category, wr.i_category)   AS category,
            ss.net_profit_store,
            sr.net_loss_store,
            cs.net_profit_catalog,
            cr.net_loss_catalog,
            ws.net_profit_web,
            wr.net_loss_web
        FROM store_sales_agg ss
        FULL OUTER JOIN store_returns_agg sr
            ON ss.d_year = sr.d_year
            AND ss.d_month_seq = sr.d_month_seq
            AND ss.i_category = sr.i_category
        FULL OUTER JOIN catalog_sales_agg cs
            ON COALESCE(ss.d_year, sr.d_year) = cs.d_year
            AND COALESCE(ss.d_month_seq, sr.d_month_seq) = cs.d_month_seq
            AND COALESCE(ss.i_category, sr.i_category) = cs.i_category
        FULL OUTER JOIN catalog_returns_agg cr
            ON COALESCE(ss.d_year, sr.d_year, cs.d_year) = cr.d_year
            AND COALESCE(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq) = cr.d_month_seq
            AND COALESCE(ss.i_category, sr.i_category, cs.i_category) = cr.i_category
        FULL OUTER JOIN web_sales_agg ws
            ON COALESCE(ss.d_year, sr.d_year, cs.d_year, cr.d_year) = ws.d_year
            AND COALESCE(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq, cr.d_month_seq) = ws.d_month_seq
            AND COALESCE(ss.i_category, sr.i_category, cs.i_category, cr.i_category) = ws.i_category
        FULL OUTER JOIN web_returns_agg wr
            ON COALESCE(ss.d_year, sr.d_year, cs.d_year, cr.d_year, ws.d_year) = wr.d_year
            AND COALESCE(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq, cr.d_month_seq, ws.d_month_seq) = wr.d_month_seq
            AND COALESCE(ss.i_category, sr.i_category, cs.i_category, cr.i_category, ws.i_category) = wr.i_category
    )
SELECT
    year,
    month_seq,
    category,
    COALESCE(net_profit_store, 0) + COALESCE(net_profit_catalog, 0) + COALESCE(net_profit_web, 0)
    - COALESCE(net_loss_store, 0) - COALESCE(net_loss_catalog, 0) - COALESCE(net_loss_web, 0) AS net_profit_after_returns,
    COALESCE(net_profit_store, 0)   AS net_profit_store,
    COALESCE(net_loss_store, 0)     AS net_loss_store,
    COALESCE(net_profit_catalog, 0) AS net_profit_catalog,
    COALESCE(net_loss_catalog, 0)   AS net_loss_catalog,
    COALESCE(net_profit_web, 0)     AS net_profit_web,
    COALESCE(net_loss_web, 0)       AS net_loss_web
FROM combined
ORDER BY year, month_seq, category
