WITH catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        sum(cs.cs_net_profit) AS catalog_sales_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        sum(ws.ws_net_profit) AS web_sales_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
),
catalog_returns_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        sum(cr.cr_net_loss) AS catalog_returns_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
),
web_returns_agg AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        sum(wr.wr_net_loss) AS web_returns_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
)
SELECT
    coalesce(cs.d_year, ws.d_year, cr.d_year, wr.d_year) AS year,
    coalesce(cs.d_moy, ws.d_moy, cr.d_moy, wr.d_moy) AS month,
    coalesce(cs.i_category, ws.i_category, cr.i_category, wr.i_category) AS category,
    coalesce(cs.catalog_sales_profit, 0) + coalesce(ws.web_sales_profit, 0)
        - coalesce(cr.catalog_returns_loss, 0) - coalesce(wr.web_returns_loss, 0) AS total_net_profit,
    coalesce(cs.catalog_sales_profit, 0) AS catalog_sales_profit,
    coalesce(ws.web_sales_profit, 0) AS web_sales_profit,
    coalesce(cr.catalog_returns_loss, 0) AS catalog_returns_loss,
    coalesce(wr.web_returns_loss, 0) AS web_returns_loss
FROM catalog_sales_agg cs
FULL OUTER JOIN web_sales_agg ws
    ON cs.d_year = ws.d_year
   AND cs.d_moy = ws.d_moy
   AND cs.i_category = ws.i_category
FULL OUTER JOIN catalog_returns_agg cr
    ON coalesce(cs.d_year, ws.d_year) = cr.d_year
   AND coalesce(cs.d_moy, ws.d_moy) = cr.d_moy
   AND coalesce(cs.i_category, ws.i_category) = cr.i_category
FULL OUTER JOIN web_returns_agg wr
    ON coalesce(cs.d_year, ws.d_year, cr.d_year) = wr.d_year
   AND coalesce(cs.d_moy, ws.d_moy, cr.d_moy) = wr.d_moy
   AND coalesce(cs.i_category, ws.i_category, cr.i_category) = wr.i_category
ORDER BY total_net_profit DESC
LIMIT 10
