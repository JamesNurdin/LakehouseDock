WITH catalog_sales_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_moy,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(*) AS catalog_orders
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY i.i_category, d.d_year, d.d_moy
),
web_sales_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_moy,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(*) AS web_orders
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY i.i_category, d.d_year, d.d_moy
),
catalog_returns_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_moy,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY i.i_category, d.d_year, d.d_moy
)
SELECT
    COALESCE(cs.i_category, ws.i_category, cr.i_category) AS category,
    COALESCE(cs.d_year, ws.d_year, cr.d_year) AS sales_year,
    COALESCE(cs.d_moy, ws.d_moy, cr.d_moy) AS sales_month,
    cs.catalog_net_paid,
    cs.catalog_net_profit,
    ws.web_net_paid,
    ws.web_net_profit,
    cr.total_return_amount,
    cr.total_return_loss
FROM catalog_sales_agg cs
FULL OUTER JOIN web_sales_agg ws
    ON cs.i_category = ws.i_category
   AND cs.d_year = ws.d_year
   AND cs.d_moy = ws.d_moy
FULL OUTER JOIN catalog_returns_agg cr
    ON COALESCE(cs.i_category, ws.i_category) = cr.i_category
   AND COALESCE(cs.d_year, ws.d_year) = cr.d_year
   AND COALESCE(cs.d_moy, ws.d_moy) = cr.d_moy
ORDER BY category, sales_year, sales_month
