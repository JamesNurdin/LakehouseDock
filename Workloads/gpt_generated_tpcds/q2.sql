WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.total_quantity,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    s.total_net_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    (s.total_quantity - COALESCE(r.total_return_quantity, 0)) AS net_quantity_sold
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.i_category = r.i_category
ORDER BY s.d_year, s.d_month_seq, s.i_category
