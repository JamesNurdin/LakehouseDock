WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2003-01-01'
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2003-01-01'
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.total_sales,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.sales_cnt,
    COALESCE(r.return_cnt, 0) AS return_cnt
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.i_category = r.i_category
ORDER BY s.d_year DESC, s.d_month_seq DESC, net_profit_after_returns DESC
