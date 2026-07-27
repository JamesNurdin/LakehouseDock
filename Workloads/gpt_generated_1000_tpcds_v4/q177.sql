WITH filtered AS (
    SELECT
        i.inv_date_sk,
        i.inv_item_sk,
        i.inv_warehouse_sk,
        i.inv_quantity_on_hand,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        w.w_county,
        w.w_gmt_offset,
        w.w_warehouse_sq_ft
    FROM inventory i
    JOIN warehouse w
      ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_date_sk BETWEEN 2450840 AND 2451080
      AND i.inv_item_sk IN (22, 28, 34, 38)
      AND i.inv_quantity_on_hand > 0
      AND w.w_gmt_offset = -6.00
      AND w.w_county IN ('Richland County', 'Williamson County')
      AND w.w_state = 'TX'
      AND w.w_warehouse_sq_ft >= 50000
)
SELECT
    w_state,
    w_city,
    w_county,
    COUNT(DISTINCT inv_item_sk) AS distinct_item_cnt,
    SUM(inv_quantity_on_hand) AS total_qty,
    AVG(inv_quantity_on_hand) AS avg_qty,
    MIN(inv_quantity_on_hand) AS min_qty,
    MAX(inv_quantity_on_hand) AS max_qty
FROM filtered
GROUP BY w_state, w_city, w_county
ORDER BY total_qty DESC
LIMIT 100
