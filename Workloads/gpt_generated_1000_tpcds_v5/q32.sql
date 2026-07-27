WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
    HAVING SUM(inv_quantity_on_hand) > 100
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    d.d_year,
    d.d_month_seq,
    SUM(cs.cs_net_profit) AS total_net_profit,
    inv_agg.total_qty_on_hand,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank,
    CASE
        WHEN SUM(cs.cs_net_profit) > 100000 THEN 'High'
        ELSE 'Medium'
    END AS profit_category
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inv_agg
    ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
   AND inv_agg.inv_date_sk = d.d_date_sk
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND w.w_state = 'CA'
  AND w.w_warehouse_sq_ft >= 500000
  AND d.d_month_seq BETWEEN 1200 AND 1220
  AND cs.cs_quantity > 1
  AND cs.cs_net_profit > 0
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
          AND cs2.cs_sold_date_sk = d.d_date_sk
          AND cs2.cs_net_profit > 50000
        LIMIT 1
      )
GROUP BY w.w_warehouse_id, w.w_warehouse_name, d.d_year, d.d_month_seq, inv_agg.total_qty_on_hand
ORDER BY d.d_year, profit_rank
