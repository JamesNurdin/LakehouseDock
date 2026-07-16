WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cp.cp_department,
        sm.sm_type,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt,
        AVG(cs.cs_sales_price) AS avg_sales_price
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND cp.cp_department = 'DEPARTMENT'
    GROUP BY d.d_year, d.d_month_seq, cp.cp_department, sm.sm_type
    HAVING SUM(cs.cs_net_paid_inc_tax) > 5000
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns,
        COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.cp_department,
    s.sm_type,
    s.total_sales,
    s.total_profit,
    s.total_discount,
    s.sales_cnt,
    s.avg_sales_price,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.returns_cnt, 0) AS returns_cnt,
    s.total_sales - COALESCE(r.total_returns, 0) AS net_sales,
    RANK() OVER (PARTITION BY s.d_year, s.cp_department ORDER BY s.total_profit DESC) AS profit_rank_by_dept
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
ORDER BY s.d_year, s.d_month_seq, profit_rank_by_dept
LIMIT 100
