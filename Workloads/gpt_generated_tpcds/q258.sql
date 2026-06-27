WITH sales_monthly AS (
    SELECT
        d_sold.d_year AS year,
        d_sold.d_month_seq AS month_seq,
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity_sold
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    GROUP BY d_sold.d_year, d_sold.d_month_seq, cs.cs_item_sk
),
returns_monthly AS (
    SELECT
        d_ret.d_year AS year,
        d_ret.d_month_seq AS month_seq,
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    GROUP BY d_ret.d_year, d_ret.d_month_seq, cr.cr_item_sk
)
SELECT
    s.year,
    s.month_seq,
    s.item_sk,
    s.total_sales,
    s.total_profit,
    s.total_quantity_sold,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    (s.total_sales - COALESCE(r.total_return_amount, 0)) AS net_sales_after_returns,
    (s.total_profit - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
    CASE WHEN s.total_quantity_sold > 0
        THEN (COALESCE(r.total_return_qty, 0) * 100.0 / s.total_quantity_sold)
        ELSE 0
    END AS return_rate_percent
FROM sales_monthly s
LEFT JOIN returns_monthly r
    ON s.year = r.year
    AND s.month_seq = r.month_seq
    AND s.item_sk = r.item_sk
WHERE s.year = 2000
ORDER BY s.year, s.month_seq, s.item_sk
