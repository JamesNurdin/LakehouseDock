WITH ship_mode_aggregates AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_type,
        sm.sm_carrier,
        sum(cs.cs_net_profit) AS total_net_profit,
        sum(cr.cr_net_loss) AS total_net_loss,
        sum(cs.cs_quantity) AS total_quantity_sold,
        sum(cr.cr_return_quantity) AS total_return_quantity,
        avg(cr.cr_return_amount) AS avg_return_amount,
        count(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY
        sm.sm_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_type,
        sm.sm_carrier
)
SELECT
    sm_ship_mode_id,
    sm_type,
    sm_carrier,
    total_net_profit,
    total_net_loss,
    total_quantity_sold,
    total_return_quantity,
    avg_return_amount,
    distinct_orders,
    total_return_quantity / nullif(total_quantity_sold, 0) AS return_quantity_ratio,
    total_net_loss / nullif(total_net_profit, 0) AS net_loss_to_profit_ratio,
    rank() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM ship_mode_aggregates
ORDER BY profit_rank
