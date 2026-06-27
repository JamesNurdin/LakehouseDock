WITH sales AS (
    SELECT
        i.i_category,
        w.w_warehouse_id,
        sm.sm_type,
        SUM(cs.cs_net_paid) AS total_sales_net_paid,
        SUM(cs.cs_net_profit) AS total_sales_net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY
        i.i_category,
        w.w_warehouse_id,
        sm.sm_type
),
returns AS (
    SELECT
        i.i_category,
        w.w_warehouse_id,
        sm.sm_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_net_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY
        i.i_category,
        w.w_warehouse_id,
        sm.sm_type
)
SELECT
    s.i_category,
    s.w_warehouse_id,
    s.sm_type,
    s.total_sales_net_paid,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_sales_net_profit - COALESCE(r.total_return_net_loss, 0) AS net_profit_after_returns
FROM sales s
LEFT JOIN returns r
    ON s.i_category = r.i_category
    AND s.w_warehouse_id = r.w_warehouse_id
    AND s.sm_type = r.sm_type
ORDER BY net_profit_after_returns DESC
LIMIT 10
