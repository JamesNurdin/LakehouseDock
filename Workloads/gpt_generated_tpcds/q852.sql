WITH sales_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
returns_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    COALESCE(sm.d_year, rm.d_year) AS year,
    COALESCE(sm.d_month_seq, rm.d_month_seq) AS month_seq,
    COALESCE(sm.i_category, rm.i_category) AS category,
    COALESCE(sm.total_sales_profit, 0) AS total_sales_profit,
    COALESCE(rm.total_return_amount, 0) AS total_return_amount,
    COALESCE(sm.total_sales_profit, 0) - COALESCE(rm.total_return_amount, 0) AS net_profit_after_returns,
    COALESCE(sm.sales_cnt, 0) AS sales_cnt,
    COALESCE(rm.returns_cnt, 0) AS returns_cnt
FROM sales_monthly sm
FULL OUTER JOIN returns_monthly rm
    ON sm.d_year = rm.d_year
   AND sm.d_month_seq = rm.d_month_seq
   AND sm.i_category = rm.i_category
ORDER BY year, month_seq, category
