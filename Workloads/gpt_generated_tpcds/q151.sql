WITH catalog_sales_agg AS (
    SELECT
        i.i_category AS category,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(cs.cs_quantity) AS catalog_quantity
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
web_sales_agg AS (
    SELECT
        i.i_category AS category,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
catalog_returns_agg AS (
    SELECT
        i.i_category AS category,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(cr.cr_net_loss) AS return_loss,
        SUM(cr.cr_return_quantity) AS return_quantity
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY i.i_category, d.d_year, d.d_month_seq
)
SELECT
    COALESCE(cs.category, ws.category, cr.category) AS category,
    COALESCE(cs.year, ws.year, cr.year) AS year,
    COALESCE(cs.month_seq, ws.month_seq, cr.month_seq) AS month_seq,
    COALESCE(cs.catalog_profit, 0) + COALESCE(ws.web_profit, 0) - COALESCE(cr.return_loss, 0) AS net_profit,
    COALESCE(cs.catalog_quantity, 0) + COALESCE(ws.web_quantity, 0) - COALESCE(cr.return_quantity, 0) AS net_quantity
FROM catalog_sales_agg cs
FULL OUTER JOIN web_sales_agg ws
    ON cs.category = ws.category
   AND cs.year = ws.year
   AND cs.month_seq = ws.month_seq
FULL OUTER JOIN catalog_returns_agg cr
    ON COALESCE(cs.category, ws.category) = cr.category
   AND COALESCE(cs.year, ws.year) = cr.year
   AND COALESCE(cs.month_seq, ws.month_seq) = cr.month_seq
WHERE COALESCE(cs.year, ws.year, cr.year) = 2001
ORDER BY net_profit DESC
LIMIT 20
