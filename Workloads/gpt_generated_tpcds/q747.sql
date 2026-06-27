WITH sales_agg AS (
    SELECT
        cp.cp_department AS department,
        dd.d_year AS year,
        dd.d_month_seq AS month_seq,
        sum(cs.cs_net_paid) AS total_sales,
        sum(cs.cs_net_profit) AS total_profit,
        count(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE dd.d_year = 2001
    GROUP BY cp.cp_department, dd.d_year, dd.d_month_seq
),
returns_agg AS (
    SELECT
        cp.cp_department AS department,
        dd.d_year AS year,
        dd.d_month_seq AS month_seq,
        sum(cr.cr_refunded_cash) AS total_refunded,
        sum(cr.cr_return_amount) AS total_return_amount,
        count(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE dd.d_year = 2001
    GROUP BY cp.cp_department, dd.d_year, dd.d_month_seq
)
SELECT
    s.department,
    s.year,
    s.month_seq,
    s.total_sales,
    s.total_profit,
    coalesce(r.total_refunded, 0) AS total_refunded,
    s.total_sales - coalesce(r.total_refunded, 0) AS net_sales_after_refunds,
    s.total_profit - coalesce(r.total_refunded, 0) AS net_profit_after_refunds,
    s.sales_cnt,
    coalesce(r.returns_cnt, 0) AS returns_cnt
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.department = r.department
 AND s.year = r.year
 AND s.month_seq = r.month_seq
ORDER BY s.total_sales DESC
LIMIT 20
