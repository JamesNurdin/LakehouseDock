WITH catalog_sales_agg AS (
    SELECT
        i.i_category AS i_category,
        d.d_year AS d_year,
        d.d_moy AS d_moy,
        SUM(cs.cs_net_profit) AS profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_moy
),
catalog_returns_agg AS (
    SELECT
        i.i_category AS i_category,
        d.d_year AS d_year,
        d.d_moy AS d_moy,
        -SUM(cr.cr_net_loss) AS profit
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_moy
),
web_sales_agg AS (
    SELECT
        i.i_category AS i_category,
        d.d_year AS d_year,
        d.d_moy AS d_moy,
        SUM(ws.ws_net_profit) AS profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year, d.d_moy
),
combined AS (
    SELECT i_category, d_year, d_moy, profit FROM catalog_sales_agg
    UNION ALL
    SELECT i_category, d_year, d_moy, profit FROM catalog_returns_agg
    UNION ALL
    SELECT i_category, d_year, d_moy, profit FROM web_sales_agg
)
SELECT
    i_category,
    d_year,
    d_moy,
    SUM(profit) AS total_profit
FROM combined
GROUP BY i_category, d_year, d_moy
ORDER BY total_profit DESC
LIMIT 100
