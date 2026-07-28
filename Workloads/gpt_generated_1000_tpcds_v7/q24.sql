WITH item_stats AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        inv.inv_warehouse_sk,
        t.t_hour,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amt,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_return_qty
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE inv.inv_warehouse_sk IN (14, 15)
      AND t.t_hour BETWEEN 8 AND 12
      AND i.i_formulation LIKE '%goldenrod%'
    GROUP BY i.i_item_sk, i.i_product_name, inv.inv_warehouse_sk, t.t_hour
),
agg AS (
    SELECT
        inv_warehouse_sk AS warehouse_sk,
        AVG(total_return_amt) AS avg_return_amt,
        SUM(total_qty_on_hand) AS sum_qty_on_hand
    FROM item_stats
    WHERE total_return_amt > 100
    GROUP BY inv_warehouse_sk
    HAVING SUM(total_qty_on_hand) > 500
)
SELECT
    warehouse_sk,
    avg_return_amt,
    sum_qty_on_hand,
    ROW_NUMBER() OVER (PARTITION BY warehouse_sk ORDER BY avg_return_amt DESC) AS rn
FROM agg
ORDER BY avg_return_amt DESC
LIMIT 100
