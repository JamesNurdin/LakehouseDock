WITH warehouse_meal_agg AS (
    SELECT
        i.inv_warehouse_sk,
        d.t_meal_time,
        d.t_sub_shift,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        AVG(i.inv_quantity_on_hand) AS avg_qty_per_item
    FROM inventory i
    JOIN time_dim d
        ON i.inv_date_sk = d.t_time_sk
    WHERE d.t_sub_shift IN ('morning', 'afternoon')
      AND i.inv_quantity_on_hand >= 400
    GROUP BY i.inv_warehouse_sk, d.t_meal_time, d.t_sub_shift
    HAVING SUM(i.inv_quantity_on_hand) > 800
)
SELECT
    wma.inv_warehouse_sk,
    wma.t_meal_time,
    wma.t_sub_shift,
    wma.total_qty,
    wma.distinct_items,
    wma.avg_qty_per_item,
    wma.total_qty * 1.0 / SUM(wma.total_qty) OVER (PARTITION BY wma.t_meal_time) AS pct_of_meal_time,
    RANK() OVER (PARTITION BY wma.t_meal_time ORDER BY wma.total_qty DESC) AS warehouse_rank
FROM warehouse_meal_agg wma
ORDER BY wma.t_meal_time, warehouse_rank
