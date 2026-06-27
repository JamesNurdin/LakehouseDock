/*
  Net revenue (profit) per month and item category across all sales channels.
  Profit from catalog and web sales is reduced by the net loss from returns
  (catalog, web and store). The result is grouped by calendar month and the
  item category (i_category) and ordered chronologically.
*/
WITH catalog_sales_monthly AS (
    SELECT
        date_trunc('month', d.d_date) AS month,
        i.i_category,
        SUM(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY date_trunc('month', d.d_date), i.i_category
),
catalog_returns_monthly AS (
    SELECT
        date_trunc('month', d.d_date) AS month,
        i.i_category,
        SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY date_trunc('month', d.d_date), i.i_category
),
web_sales_monthly AS (
    SELECT
        date_trunc('month', d.d_date) AS month,
        i.i_category,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY date_trunc('month', d.d_date), i.i_category
),
web_returns_monthly AS (
    SELECT
        date_trunc('month', d.d_date) AS month,
        i.i_category,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY date_trunc('month', d.d_date), i.i_category
),
store_returns_monthly AS (
    SELECT
        date_trunc('month', d.d_date) AS month,
        i.i_category,
        SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY date_trunc('month', d.d_date), i.i_category
),
all_month_category AS (
    SELECT month, i_category FROM catalog_sales_monthly
    UNION
    SELECT month, i_category FROM catalog_returns_monthly
    UNION
    SELECT month, i_category FROM web_sales_monthly
    UNION
    SELECT month, i_category FROM web_returns_monthly
    UNION
    SELECT month, i_category FROM store_returns_monthly
)
SELECT
    amc.month,
    amc.i_category,
    COALESCE(cs.catalog_net_profit, 0) 
    + COALESCE(ws.web_net_profit, 0)
    - COALESCE(cr.catalog_net_loss, 0)
    - COALESCE(wr.web_net_loss, 0)
    - COALESCE(sr.store_net_loss, 0) AS net_revenue
FROM all_month_category amc
LEFT JOIN catalog_sales_monthly cs   ON amc.month = cs.month   AND amc.i_category = cs.i_category
LEFT JOIN catalog_returns_monthly cr ON amc.month = cr.month   AND amc.i_category = cr.i_category
LEFT JOIN web_sales_monthly ws       ON amc.month = ws.month   AND amc.i_category = ws.i_category
LEFT JOIN web_returns_monthly wr     ON amc.month = wr.month   AND amc.i_category = wr.i_category
LEFT JOIN store_returns_monthly sr   ON amc.month = sr.month   AND amc.i_category = sr.i_category
ORDER BY amc.month, amc.i_category
