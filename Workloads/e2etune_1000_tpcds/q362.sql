WITH inventory_by_warehouse AS (
    SELECT inv_warehouse_sk, SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
),
sales_agg AS (
    SELECT
        w.w_warehouse_name,
        t.t_hour,
        t.t_shift,
        SUM(cs.cs_net_paid_inc_ship) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_net_profit) AS avg_profit,
        (SUM(cs.cs_net_paid_inc_ship) - SUM(cs.cs_net_profit)) AS sales_minus_profit,
        (SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid_inc_ship), 0)) * 100 AS profit_margin_pct,
        ibw.total_on_hand
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory_by_warehouse ibw ON ibw.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_coupon_amt > 500
      AND cs.cs_promo_sk IN (1023, 1057, 1374)
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY w.w_warehouse_name, t.t_hour, t.t_shift, ibw.total_on_hand
    HAVING SUM(cs.cs_net_profit) > 0
)
SELECT
    w_warehouse_name,
    t_hour,
    t_shift,
    total_sales,
    total_profit,
    avg_profit,
    sales_minus_profit,
    profit_margin_pct,
    total_on_hand,
    RANK() OVER (PARTITION BY w_warehouse_name ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 10
