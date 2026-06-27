WITH sales AS (
    SELECT
        cp.cp_department AS cp_department,
        cp.cp_catalog_number AS cp_catalog_number,
        d.d_year AS d_year,
        d.d_moy AS d_month,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY cp.cp_department, cp.cp_catalog_number, d.d_year, d.d_moy
),
returns AS (
    SELECT
        cp.cp_department AS cp_department,
        cp.cp_catalog_number AS cp_catalog_number,
        d.d_year AS d_year,
        d.d_moy AS d_month,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY cp.cp_department, cp.cp_catalog_number, d.d_year, d.d_moy
)
SELECT
    s.cp_department,
    s.cp_catalog_number,
    s.d_year,
    s.d_month,
    s.total_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_profit - COALESCE(r.total_return_amount, 0) AS net_profit_after_returns
FROM sales s
LEFT JOIN returns r
    ON s.cp_department = r.cp_department
    AND s.cp_catalog_number = r.cp_catalog_number
    AND s.d_year = r.d_year
    AND s.d_month = r.d_month
ORDER BY net_profit_after_returns DESC
