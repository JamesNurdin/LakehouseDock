WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_profit,
        d.d_year,
        d.d_moy,
        sm.sm_ship_mode_id
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_order_number, cr.cr_item_sk
),
sales_with_returns AS (
    SELECT
        s.cs_order_number,
        s.cs_item_sk,
        s.cs_net_profit,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        s.d_year,
        s.d_moy,
        s.sm_ship_mode_id
    FROM sales s
    LEFT JOIN returns r
        ON s.cs_order_number = r.cr_order_number
       AND s.cs_item_sk = r.cr_item_sk
)
SELECT
    s.d_year,
    s.d_moy,
    s.sm_ship_mode_id,
    SUM(s.cs_net_profit) AS total_sales_profit,
    SUM(s.total_return_loss) AS total_return_loss,
    SUM(s.cs_net_profit) - SUM(s.total_return_loss) AS net_profit_after_returns,
    COUNT(DISTINCT s.cs_order_number) AS num_sales_orders,
    COUNT(DISTINCT CASE WHEN s.total_return_loss > 0 THEN s.cs_order_number END) AS num_return_orders
FROM sales_with_returns s
GROUP BY s.d_year, s.d_moy, s.sm_ship_mode_id
ORDER BY s.d_year, s.d_moy, s.sm_ship_mode_id
