WITH sales_agg AS (
    SELECT
        ds.d_year,
        ds.d_month_seq,
        i.i_category,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_net_paid) AS total_sales_amount,
        SUM(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE ds.d_year = 2001
    GROUP BY ds.d_year, ds.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        dr.d_year,
        dr.d_month_seq,
        i.i_category,
        SUM(cr.cr_return_quantity) AS total_quantity_returned,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE dr.d_year = 2001
    GROUP BY dr.d_year, dr.d_month_seq, i.i_category
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.total_quantity_sold,
    s.total_sales_amount,
    s.total_sales_profit,
    COALESCE(r.total_quantity_returned, 0) AS total_quantity_returned,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    CASE WHEN s.total_quantity_sold = 0 THEN 0
         ELSE CAST(COALESCE(r.total_quantity_returned, 0) AS double) / s.total_quantity_sold
    END AS return_rate
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.i_category = r.i_category
ORDER BY s.d_year, s.d_month_seq, s.i_category
