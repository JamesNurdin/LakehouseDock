WITH sales AS (
    SELECT
        d.d_year,
        i.i_category,
        cs.cs_order_number,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '1999-01-01' AND d.d_date < DATE '2001-01-01'
),
returns AS (
    SELECT
        d.d_year,
        i.i_category,
        cr.cr_order_number,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '1999-01-01' AND d.d_date < DATE '2001-01-01'
    GROUP BY d.d_year, i.i_category, cr.cr_order_number
)
SELECT
    s.d_year,
    s.i_category,
    SUM(s.cs_net_paid_inc_tax) AS total_sales_inc_tax,
    SUM(s.cs_net_profit) AS total_sales_profit,
    COALESCE(SUM(r.total_return_loss), 0) AS total_returns_loss,
    SUM(s.cs_net_profit) - COALESCE(SUM(r.total_return_loss), 0) AS net_profit_after_returns,
    SUM(s.cs_ext_discount_amt) / NULLIF(SUM(s.cs_quantity), 0) AS avg_discount_per_item,
    COUNT(DISTINCT s.cs_order_number) AS distinct_sales_orders,
    COUNT(DISTINCT r.cr_order_number) AS distinct_return_orders
FROM sales s
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
    AND s.d_year = r.d_year
    AND s.i_category = r.i_category
GROUP BY s.d_year, s.i_category
ORDER BY s.d_year, s.i_category
