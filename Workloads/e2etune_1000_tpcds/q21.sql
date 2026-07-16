WITH aggregated AS (
    SELECT
        cc.cc_state,
        w.w_state,
        cc.cc_division_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i
      ON w.w_warehouse_sk = i.inv_warehouse_sk
    WHERE cc.cc_rec_end_date = DATE '2000-12-31'
      AND cc.cc_state IN ('TN', 'GA')
      AND cs.cs_quantity >= 5
      AND i.inv_quantity_on_hand > 0
    GROUP BY
        cc.cc_state,
        w.w_state,
        cc.cc_division_name
    HAVING SUM(cs.cs_net_paid) > 10000
)
SELECT
    cc_state,
    w_state,
    cc_division_name,
    total_net_paid,
    total_net_profit,
    avg_discount,
    distinct_orders,
    RANK() OVER (PARTITION BY cc_state ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 20
