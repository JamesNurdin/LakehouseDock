WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_time_sk,
        cs.cs_ship_mode_sk,
        cs.cs_net_profit,
        cs.cs_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        hd.hd_vehicle_count,
        sm.sm_carrier,
        td.t_hour
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_net_profit > 0
      AND cr.cr_return_amount > 0
      AND hd.hd_vehicle_count >= 1
      AND sm.sm_carrier = 'UPS'
)
SELECT
    sa.cs_order_number,
    sa.cs_net_profit,
    sa.cs_quantity,
    sa.t_hour,
    sa.sm_carrier,
    CASE WHEN EXISTS (
            SELECT 1
            FROM web_sales ws
            WHERE ws.ws_sold_time_sk = sa.cs_sold_time_sk
              AND ws.ws_wholesale_cost > 50
              AND ws.ws_net_paid_inc_ship > 1000
        ) THEN 1 ELSE 0 END AS high_value_web_sale_flag,
    RANK() OVER (PARTITION BY sa.sm_carrier ORDER BY sa.cs_net_profit DESC) AS profit_rank_by_carrier
FROM sales_agg sa
WHERE sa.t_hour BETWEEN 9 AND 17
  AND sa.cs_quantity <= 10
ORDER BY profit_rank_by_carrier ASC
LIMIT 100
