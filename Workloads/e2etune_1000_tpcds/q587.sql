WITH sales_agg AS (
    SELECT
        w.w_warehouse_name,
        d.d_fy_quarter_seq AS quarter,
        t.t_hour AS hour,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_quantity), 0) AS profit_per_unit,
        inv_agg.total_qty_on_hand
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN (
        SELECT inv.inv_warehouse_sk,
               d2.d_fy_quarter_seq,
               SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory inv
        JOIN date_dim d2 ON inv.inv_date_sk = d2.d_date_sk
        GROUP BY inv.inv_warehouse_sk, d2.d_fy_quarter_seq
    ) inv_agg
        ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
        AND inv_agg.d_fy_quarter_seq = d.d_fy_quarter_seq
    WHERE cs.cs_ext_discount_amt > 500
      AND d.d_weekend = 'N'
      AND t.t_hour BETWEEN 9 AND 21
    GROUP BY w.w_warehouse_name, d.d_fy_quarter_seq, t.t_hour, inv_agg.total_qty_on_hand
    HAVING SUM(cs.cs_net_profit) > 1000
)
SELECT
    s.w_warehouse_name,
    s.quarter,
    s.hour,
    s.total_net_profit,
    s.total_quantity,
    s.avg_discount,
    s.profit_per_unit,
    s.total_qty_on_hand,
    RANK() OVER (PARTITION BY s.quarter ORDER BY s.total_net_profit DESC) AS warehouse_rank
FROM sales_agg s
ORDER BY s.quarter, s.profit_per_unit DESC
LIMIT 50
