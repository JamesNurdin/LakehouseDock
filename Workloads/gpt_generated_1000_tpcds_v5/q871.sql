WITH filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cs.cs_wholesale_cost,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        td.t_shift
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE td.t_shift IN ('first', 'second')
      AND td.t_time BETWEEN 4 AND 18
      AND sm.sm_contract = 'P7FBIt8yd'
      AND cs.cs_net_paid_inc_tax >= 1000
      AND cs.cs_wholesale_cost < 80
)
SELECT
    cs_order_number,
    cs_net_paid_inc_tax,
    cs_net_profit,
    sm_ship_mode_id,
    sm_carrier,
    t_shift,
    CASE WHEN cs_net_profit > 500 THEN 'High' ELSE 'Low' END AS profit_category,
    RANK() OVER (PARTITION BY sm_ship_mode_id ORDER BY cs_net_paid_inc_tax DESC) AS rank_by_ship_mode,
    ROW_NUMBER() OVER (PARTITION BY t_shift ORDER BY cs_net_paid_inc_tax DESC) AS row_num_by_shift
FROM filtered
ORDER BY rank_by_ship_mode ASC, cs_net_paid_inc_tax DESC
LIMIT 100
