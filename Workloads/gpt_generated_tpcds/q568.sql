WITH sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        w.w_state,
        cp.cp_department,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity_sold
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, d.d_month_seq, i.i_category, w.w_state, cp.cp_department
),
returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        w.w_state,
        cp.cp_department,
        SUM(cr.cr_return_amt_inc_tax) AS total_returns,
        SUM(cr.cr_return_quantity) AS total_quantity_returned
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, d.d_month_seq, i.i_category, w.w_state, cp.cp_department
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.w_state,
    s.cp_department,
    s.total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    s.total_sales - COALESCE(r.total_returns, 0) AS net_revenue,
    s.total_quantity_sold,
    COALESCE(r.total_quantity_returned, 0) AS total_quantity_returned,
    s.total_quantity_sold - COALESCE(r.total_quantity_returned, 0) AS net_quantity
FROM sales s
LEFT JOIN returns r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.i_category = r.i_category
   AND s.w_state = r.w_state
   AND s.cp_department = r.cp_department
ORDER BY s.d_year, s.d_month_seq, s.i_category, s.w_state, s.cp_department
