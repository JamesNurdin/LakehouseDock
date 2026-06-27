WITH catalog_agg AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category AS category,
        SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year >= 2000
    GROUP BY d.d_year, d.d_moy, i.i_category
),
web_return_agg AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category AS category,
        SUM(wr.wr_net_loss) AS web_return_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year >= 2000
    GROUP BY d.d_year, d.d_moy, i.i_category
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category AS category,
        SUM(ws.ws_net_profit) AS web_sales_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year >= 2000
    GROUP BY d.d_year, d.d_moy, i.i_category
)
SELECT
    COALESCE(ca.year, wr.year, ws.year) AS year,
    COALESCE(ca.month, wr.month, ws.month) AS month,
    COALESCE(ca.category, wr.category, ws.category) AS category,
    ca.catalog_net_loss,
    wr.web_return_net_loss,
    ws.web_sales_net_profit,
    (COALESCE(ws.web_sales_net_profit, 0) - COALESCE(ca.catalog_net_loss, 0) - COALESCE(wr.web_return_net_loss, 0)) AS net_effect
FROM catalog_agg ca
FULL OUTER JOIN web_return_agg wr
    ON ca.year = wr.year
    AND ca.month = wr.month
    AND ca.category = wr.category
FULL OUTER JOIN web_sales_agg ws
    ON COALESCE(ca.year, wr.year) = ws.year
    AND COALESCE(ca.month, wr.month) = ws.month
    AND COALESCE(ca.category, wr.category) = ws.category
ORDER BY year, month, category
