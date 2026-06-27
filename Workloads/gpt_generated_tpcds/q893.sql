WITH sales_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_name,
        i.i_category,
        SUM(cs.cs_net_profit) AS sales_profit,
        SUM(cs.cs_ext_sales_price) AS sales_revenue,
        COUNT(*) AS sales_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, d.d_month_seq, w.w_warehouse_name, i.i_category
),
returns_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_name,
        i.i_category,
        SUM(cr.cr_net_loss) AS returns_loss,
        SUM(cr.cr_return_amount) AS returns_amount,
        COUNT(*) AS return_orders
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, d.d_month_seq, w.w_warehouse_name, i.i_category
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.w_warehouse_name,
    s.i_category,
    s.sales_profit,
    COALESCE(r.returns_loss, 0) AS returns_loss,
    s.sales_profit - COALESCE(r.returns_loss, 0) AS net_profit_after_returns
FROM sales_monthly s
LEFT JOIN returns_monthly r
    ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.w_warehouse_name = r.w_warehouse_name
    AND s.i_category = r.i_category
ORDER BY s.d_year, s.d_month_seq, s.w_warehouse_name, s.i_category
