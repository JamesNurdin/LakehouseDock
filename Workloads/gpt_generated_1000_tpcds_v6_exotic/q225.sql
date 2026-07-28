WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        sm.sm_carrier,
        cc.cc_name,
        r.r_reason_desc,
        cs.cs_quantity,
        cs.cs_net_profit,
        cr.cr_return_amount,
        i.inv_quantity_on_hand,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_warehouse_sk ORDER BY cs.cs_net_profit DESC) AS profit_rank
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city = 'Southlake'
      AND sm.sm_carrier IN ('UPS', 'DHL')
      AND cc.cc_class = 'Corporate'
      AND r.r_reason_desc = 'Customer Not Found'
      AND cs.cs_quantity > 5
      AND cr.cr_return_amount > 100
)
SELECT DISTINCT
    sa.w_warehouse_id,
    sa.w_warehouse_name,
    sa.w_city,
    sa.sm_carrier,
    sa.cc_name,
    sa.r_reason_desc,
    sa.profit_rank,
    sa.cs_net_profit,
    sa.inv_quantity_on_hand
FROM sales_agg sa
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = sa.cs_order_number
      AND cr2.cr_return_amount > 500
)
ORDER BY sa.profit_rank ASC, sa.cs_net_profit DESC
LIMIT 100
