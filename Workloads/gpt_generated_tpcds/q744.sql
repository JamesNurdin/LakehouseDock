WITH sales_agg AS (
    SELECT
        i.i_category AS category,
        d.d_year    AS year,
        d.d_moy     AS month,
        SUM(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        i.i_category AS category,
        d.d_year    AS year,
        d.d_moy     AS month,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_moy
)
SELECT
    s.category,
    s.year,
    s.month,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.category = r.category
   AND s.year = r.year
   AND s.month = r.month
ORDER BY s.year, s.month, s.category
