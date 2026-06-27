WITH catalog_sales_agg AS (
    SELECT
        i.i_category AS category,
        d.d_year    AS year,
        d.d_month_seq AS month,
        SUM(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
web_sales_agg AS (
    SELECT
        i.i_category AS category,
        d.d_year    AS year,
        d.d_month_seq AS month,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
catalog_returns_agg AS (
    SELECT
        i.i_category AS category,
        d.d_year    AS year,
        d.d_month_seq AS month,
        SUM(cr.cr_net_loss) AS returns_net_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY i.i_category, d.d_year, d.d_month_seq
)
SELECT
    COALESCE(cs.category, ws.category, r.category) AS category,
    COALESCE(cs.year, ws.year, r.year)          AS year,
    COALESCE(cs.month, ws.month, r.month)       AS month,
    COALESCE(cs.catalog_net_profit, 0)         AS catalog_net_profit,
    COALESCE(ws.web_net_profit, 0)             AS web_net_profit,
    COALESCE(r.returns_net_loss, 0)            AS returns_net_loss,
    COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) - COALESCE(r.returns_net_loss, 0) AS net_profit_after_returns
FROM catalog_sales_agg cs
FULL OUTER JOIN web_sales_agg ws
    ON cs.category = ws.category
   AND cs.year = ws.year
   AND cs.month = ws.month
FULL OUTER JOIN catalog_returns_agg r
    ON COALESCE(cs.category, ws.category) = r.category
   AND COALESCE(cs.year, ws.year) = r.year
   AND COALESCE(cs.month, ws.month) = r.month
ORDER BY year, month, category
