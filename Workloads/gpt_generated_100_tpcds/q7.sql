WITH sales_agg AS (
    SELECT
        cp.cp_department,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cp.cp_department, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        cp.cp_department,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cp.cp_department, d.d_year, d.d_month_seq
)
SELECT
    s.cp_department AS department,
    s.d_year AS year,
    s.d_month_seq AS month_seq,
    s.total_sales,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales,
    s.total_profit,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    s.total_profit - COALESCE(r.total_net_loss, 0) AS net_profit,
    SUM(s.total_profit - COALESCE(r.total_net_loss, 0)) OVER (
        PARTITION BY s.cp_department
        ORDER BY s.d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_profit
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cp_department = r.cp_department
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
ORDER BY s.cp_department, s.d_month_seq
