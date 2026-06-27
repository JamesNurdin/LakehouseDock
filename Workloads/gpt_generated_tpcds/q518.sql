WITH sales_monthly AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity_sold
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_sk, i.i_category, d.d_year, d.d_month_seq, w.w_warehouse_sk, w.w_warehouse_name
),
returns_monthly AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_quantity_returned
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_sk, i.i_category, d.d_year, d.d_month_seq, w.w_warehouse_sk, w.w_warehouse_name
)
SELECT
    s.i_category,
    s.d_year,
    s.d_month_seq,
    s.w_warehouse_name,
    s.total_net_profit,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    s.total_quantity_sold,
    COALESCE(r.total_quantity_returned, 0) AS total_quantity_returned,
    (s.total_net_profit - COALESCE(r.total_net_loss, 0)) AS net_profit_after_returns
FROM sales_monthly s
LEFT JOIN returns_monthly r
    ON s.i_item_sk = r.i_item_sk
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.w_warehouse_sk = r.w_warehouse_sk
ORDER BY net_profit_after_returns DESC
LIMIT 10
