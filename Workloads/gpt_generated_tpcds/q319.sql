WITH sales_agg AS (
    SELECT
        cp.cp_department AS department,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cp.cp_department, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        cp.cp_department AS department,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(cr.cr_net_loss) AS total_loss
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cp.cp_department, d.d_year, d.d_moy
)
SELECT
    s.department,
    s.year,
    s.month,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_loss, 0) AS total_loss,
    s.total_sales - COALESCE(r.total_returns, 0) AS net_revenue
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.department = r.department
    AND s.year = r.year
    AND s.month = r.month
ORDER BY net_revenue DESC
LIMIT 50
