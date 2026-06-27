WITH store_sales_agg AS (
    SELECT
        d.d_date AS sale_date,
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_date, i.i_category
),
store_returns_agg AS (
    SELECT
        d.d_date AS return_date,
        i.i_category AS category,
        SUM(sr.sr_return_amt_inc_tax) AS store_return_amount,
        SUM(sr.sr_return_quantity) AS store_return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_date, i.i_category
),
catalog_sales_agg AS (
    SELECT
        d.d_date AS sale_date,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(cs.cs_quantity) AS catalog_qty,
        SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_date, i.i_category
),
catalog_returns_agg AS (
    SELECT
        d.d_date AS return_date,
        i.i_category AS category,
        SUM(cr.cr_return_amt_inc_tax) AS catalog_return_amount,
        SUM(cr.cr_return_quantity) AS catalog_return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_date, i.i_category
),
web_sales_agg AS (
    SELECT
        d.d_date AS sale_date,
        i.i_category AS category,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_date, i.i_category
),
web_returns_agg AS (
    SELECT
        d.d_date AS return_date,
        i.i_category AS category,
        SUM(wr.wr_return_amt_inc_tax) AS web_return_amount,
        SUM(wr.wr_return_quantity) AS web_return_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_date, i.i_category
)
SELECT
    DATE_TRUNC('month', COALESCE(ss.sale_date, sr.return_date, cs.sale_date, cr.return_date, ws.sale_date, wr.return_date)) AS month,
    COALESCE(ss.category, sr.category, cs.category, cr.category, ws.category, wr.category) AS category,
    SUM(COALESCE(ss.store_sales_amount, 0) - COALESCE(sr.store_return_amount, 0)) AS net_store_sales_amount,
    SUM(COALESCE(cs.catalog_sales_amount, 0) - COALESCE(cr.catalog_return_amount, 0)) AS net_catalog_sales_amount,
    SUM(COALESCE(ws.web_sales_amount, 0) - COALESCE(wr.web_return_amount, 0)) AS net_web_sales_amount,
    SUM(COALESCE(ss.store_profit, 0)) AS total_store_profit,
    SUM(COALESCE(cs.catalog_profit, 0)) AS total_catalog_profit,
    SUM(COALESCE(ws.web_profit, 0)) AS total_web_profit,
    SUM(
        COALESCE(ss.store_sales_amount, 0) - COALESCE(sr.store_return_amount, 0) +
        COALESCE(cs.catalog_sales_amount, 0) - COALESCE(cr.catalog_return_amount, 0) +
        COALESCE(ws.web_sales_amount, 0) - COALESCE(wr.web_return_amount, 0)
    ) AS total_net_sales_amount
FROM store_sales_agg ss
FULL OUTER JOIN store_returns_agg sr
    ON ss.sale_date = sr.return_date AND ss.category = sr.category
FULL OUTER JOIN catalog_sales_agg cs
    ON COALESCE(ss.sale_date, sr.return_date) = cs.sale_date
   AND COALESCE(ss.category, sr.category) = cs.category
FULL OUTER JOIN catalog_returns_agg cr
    ON cs.sale_date = cr.return_date AND cs.category = cr.category
FULL OUTER JOIN web_sales_agg ws
    ON COALESCE(cs.sale_date, cr.return_date) = ws.sale_date
   AND COALESCE(cs.category, cr.category) = ws.category
FULL OUTER JOIN web_returns_agg wr
    ON ws.sale_date = wr.return_date AND ws.category = wr.category
WHERE DATE_TRUNC('month', COALESCE(ss.sale_date, sr.return_date, cs.sale_date, cr.return_date, ws.sale_date, wr.return_date))
      BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
GROUP BY
    DATE_TRUNC('month', COALESCE(ss.sale_date, sr.return_date, cs.sale_date, cr.return_date, ws.sale_date, wr.return_date)),
    COALESCE(ss.category, sr.category, cs.category, cr.category, ws.category, wr.category)
ORDER BY month, category
