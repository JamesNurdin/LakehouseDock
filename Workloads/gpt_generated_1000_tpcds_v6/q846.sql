WITH inv_agg AS (
    SELECT
        i.inv_warehouse_sk,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        AVG(i.inv_quantity_on_hand) AS avg_qty,
        MAX(i.inv_date_sk) AS latest_date_sk
    FROM inventory i
    WHERE i.inv_quantity_on_hand > 500
      AND i.inv_date_sk BETWEEN 2450960 AND 2451088
      AND i.inv_warehouse_sk IS NOT NULL
    GROUP BY i.inv_warehouse_sk
    HAVING SUM(i.inv_quantity_on_hand) > 2000
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_city,
    inv_agg.distinct_items,
    inv_agg.total_qty,
    inv_agg.avg_qty,
    inv_agg.latest_date_sk
FROM inv_agg
LEFT JOIN warehouse w
    ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_warehouse_sq_ft > 600000
  AND w.w_street_type IN ('Street', 'Way', 'RD')
  AND w.w_state = 'CA'
ORDER BY inv_agg.total_qty DESC
LIMIT 100
