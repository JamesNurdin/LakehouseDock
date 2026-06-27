WITH sales_agg AS (
    SELECT
        ds.d_year,
        ds.d_moy,
        i.i_category,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE ds.d_year BETWEEN 1998 AND 2000
    GROUP BY ds.d_year, ds.d_moy, i.i_category
),
returns_agg AS (
    SELECT
        dr.d_year,
        dr.d_moy,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE dr.d_year BETWEEN 1998 AND 2000
    GROUP BY dr.d_year, dr.d_moy, i.i_category
)
SELECT
    s.d_year,
    s.d_moy,
    s.i_category,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    CASE WHEN s.total_quantity = 0 THEN 0
         ELSE CAST(COALESCE(r.total_return_quantity, 0) AS double) / s.total_quantity
    END AS return_rate,
    s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_moy = r.d_moy
   AND s.i_category = r.i_category
ORDER BY s.d_year, s.d_moy, s.i_category
