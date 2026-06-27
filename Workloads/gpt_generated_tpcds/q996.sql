WITH
store_sales_agg AS (
    SELECT
        d.d_date AS sales_date,
        i.i_category AS category,
        SUM(ss.ss_net_paid) AS store_sales_net_paid,
        SUM(ss.ss_net_profit) AS store_sales_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_date, i.i_category
),
store_returns_agg AS (
    SELECT
        d.d_date AS return_date,
        i.i_category AS category,
        SUM(sr.sr_net_loss) AS store_returns_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_date, i.i_category
),
web_sales_agg AS (
    SELECT
        d.d_date AS sales_date,
        i.i_category AS category,
        SUM(ws.ws_net_paid) AS web_sales_net_paid,
        SUM(ws.ws_net_profit) AS web_sales_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_date, i.i_category
),
web_returns_agg AS (
    SELECT
        d.d_date AS return_date,
        i.i_category AS category,
        SUM(wr.wr_net_loss) AS web_returns_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_date, i.i_category
),
catalog_returns_agg AS (
    SELECT
        d.d_date AS return_date,
        i.i_category AS category,
        SUM(cr.cr_net_loss) AS catalog_returns_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_date, i.i_category
),
combined AS (
    SELECT
        COALESCE(ss.sales_date, sr.return_date, ws.sales_date, wr.return_date, cr.return_date) AS trans_date,
        COALESCE(ss.category, sr.category, ws.category, wr.category, cr.category) AS category,
        COALESCE(ss.store_sales_net_paid, 0) AS store_sales_net_paid,
        COALESCE(ss.store_sales_profit, 0) AS store_sales_profit,
        COALESCE(sr.store_returns_net_loss, 0) AS store_returns_net_loss,
        COALESCE(ws.web_sales_net_paid, 0) AS web_sales_net_paid,
        COALESCE(ws.web_sales_profit, 0) AS web_sales_profit,
        COALESCE(wr.web_returns_net_loss, 0) AS web_returns_net_loss,
        COALESCE(cr.catalog_returns_net_loss, 0) AS catalog_returns_net_loss
    FROM store_sales_agg ss
    FULL OUTER JOIN store_returns_agg sr
        ON ss.sales_date = sr.return_date AND ss.category = sr.category
    FULL OUTER JOIN web_sales_agg ws
        ON COALESCE(ss.sales_date, sr.return_date) = ws.sales_date
        AND COALESCE(ss.category, sr.category) = ws.category
    FULL OUTER JOIN web_returns_agg wr
        ON COALESCE(ss.sales_date, sr.return_date, ws.sales_date) = wr.return_date
        AND COALESCE(ss.category, sr.category, ws.category) = wr.category
    FULL OUTER JOIN catalog_returns_agg cr
        ON COALESCE(ss.sales_date, sr.return_date, ws.sales_date, wr.return_date) = cr.return_date
        AND COALESCE(ss.category, sr.category, ws.category, wr.category) = cr.category
)
SELECT
    trans_date,
    category,
    store_sales_net_paid,
    store_sales_profit,
    store_returns_net_loss,
    web_sales_net_paid,
    web_sales_profit,
    web_returns_net_loss,
    catalog_returns_net_loss,
    (store_sales_net_paid + web_sales_net_paid
        - store_returns_net_loss - web_returns_net_loss - catalog_returns_net_loss) AS net_sales_excluding_profit,
    (store_sales_profit + web_sales_profit) AS total_profit
FROM combined
WHERE trans_date >= DATE '2022-01-01' AND trans_date < DATE '2023-01-01'
ORDER BY trans_date, category
