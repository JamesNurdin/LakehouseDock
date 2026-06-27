WITH sales_by_item_month AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
returns_by_item_month AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY i.i_category, d.d_year, d.d_month_seq
    UNION ALL
    SELECT
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY i.i_category, d.d_year, d.d_month_seq
    UNION ALL
    SELECT
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY i.i_category, d.d_year, d.d_month_seq
),
aggregated_returns AS (
    SELECT
        i_category,
        d_year,
        d_month_seq,
        SUM(total_return_amount) AS total_return_amount
    FROM returns_by_item_month
    GROUP BY i_category, d_year, d_month_seq
)
SELECT
    s.i_category,
    s.d_year,
    s.d_month_seq,
    s.total_sales,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales,
    s.total_profit
FROM sales_by_item_month s
LEFT JOIN aggregated_returns r
    ON s.i_category = r.i_category
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
ORDER BY s.d_year DESC, s.d_month_seq DESC, s.total_sales DESC
LIMIT 100
