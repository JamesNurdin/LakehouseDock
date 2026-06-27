WITH sales_agg AS (
    SELECT
        w.w_warehouse_name,
        i.i_category,
        date_dim.d_year,
        date_dim.d_month_seq AS month_seq,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim ON cs.cs_sold_date_sk = date_dim.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE date_dim.d_year = 2001
    GROUP BY w.w_warehouse_name, i.i_category, date_dim.d_year, date_dim.d_month_seq
),
returns_agg AS (
    SELECT
        w.w_warehouse_name,
        i.i_category,
        date_dim.d_year,
        date_dim.d_month_seq AS month_seq,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim ON cr.cr_returned_date_sk = date_dim.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE date_dim.d_year = 2001
    GROUP BY w.w_warehouse_name, i.i_category, date_dim.d_year, date_dim.d_month_seq
)
SELECT
    s.w_warehouse_name,
    s.i_category,
    s.d_year,
    s.month_seq,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_refunded_cash, 0) AS total_refunded_cash,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    s.total_profit - COALESCE(r.total_net_loss, 0) AS profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.w_warehouse_name = r.w_warehouse_name
   AND s.i_category = r.i_category
   AND s.d_year = r.d_year
   AND s.month_seq = r.month_seq
ORDER BY s.total_profit DESC
LIMIT 100
