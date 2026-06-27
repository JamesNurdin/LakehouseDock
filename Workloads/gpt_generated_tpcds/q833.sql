WITH sales_agg AS (
    SELECT
        ds.d_year,
        ds.d_month_seq,
        i.i_category,
        SUM(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE ds.d_date >= DATE '2001-01-01'
      AND ds.d_date <= DATE '2001-12-31'
    GROUP BY ds.d_year, ds.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        dr.d_year,
        dr.d_month_seq,
        i.i_category,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE dr.d_date >= DATE '2001-01-01'
      AND dr.d_date <= DATE '2001-12-31'
    GROUP BY dr.d_year, dr.d_month_seq, i.i_category
)
SELECT
    COALESCE(s.d_year, r.d_year) AS year,
    COALESCE(s.d_month_seq, r.d_month_seq) AS month_seq,
    COALESCE(s.i_category, r.i_category) AS category,
    COALESCE(s.total_sales_profit, 0) AS total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.i_category = r.i_category
ORDER BY year, month_seq, category
