-- Monthly sales and returns analysis by catalog department
WITH sales_by_dept_month AS (
    SELECT
        cp.cp_department AS department,
        d_sales.d_year AS year,
        d_sales.d_month_seq AS month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity_sold
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    GROUP BY cp.cp_department, d_sales.d_year, d_sales.d_month_seq
),
returns_by_dept_month AS (
    SELECT
        cp.cp_department AS department,
        d_returns.d_year AS year,
        d_returns.d_month_seq AS month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_quantity_returned
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_returns
        ON cr.cr_returned_date_sk = d_returns.d_date_sk
    GROUP BY cp.cp_department, d_returns.d_year, d_returns.d_month_seq
)
SELECT
    s.department,
    s.year,
    s.month_seq,
    s.total_sales_amount,
    s.total_net_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_sales_amount - COALESCE(r.total_return_amount, 0) AS net_sales_after_returns,
    s.total_quantity_sold,
    COALESCE(r.total_quantity_returned, 0) AS total_quantity_returned,
    s.total_quantity_sold - COALESCE(r.total_quantity_returned, 0) AS net_quantity_sold,
    COALESCE(r.total_return_loss, 0) AS total_return_loss
FROM sales_by_dept_month s
LEFT JOIN returns_by_dept_month r
    ON s.department = r.department
    AND s.year = r.year
    AND s.month_seq = r.month_seq
ORDER BY s.department, s.year, s.month_seq
