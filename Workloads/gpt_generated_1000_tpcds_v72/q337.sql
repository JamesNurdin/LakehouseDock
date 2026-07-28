WITH filtered_inventory AS (
    SELECT
        i.inv_date_sk,
        i.inv_item_sk,
        i.inv_warehouse_sk,
        i.inv_quantity_on_hand
    FROM inventory i
    WHERE i.inv_quantity_on_hand > 0
      AND i.inv_warehouse_sk IN (1, 6, 15)
      AND i.inv_item_sk BETWEEN 101420 AND 101450
)
SELECT
    d.d_year,
    d.d_quarter_name,
    f.inv_warehouse_sk,
    SUM(f.inv_quantity_on_hand) AS total_qty,
    COUNT(DISTINCT f.inv_item_sk) AS distinct_items,
    MIN(f.inv_quantity_on_hand) AS min_qty,
    MAX(f.inv_quantity_on_hand) AS max_qty
FROM filtered_inventory f
JOIN date_dim d
    ON f.inv_date_sk = d.d_date_sk
WHERE d.d_fy_week_seq BETWEEN 2 AND 16
  AND d.d_week_seq IN (9, 14, 15)
GROUP BY GROUPING SETS (
    (d.d_year, d.d_quarter_name, f.inv_warehouse_sk),
    (d.d_year, d.d_quarter_name),
    (d.d_year),
    ()
)
ORDER BY d.d_year DESC, d.d_quarter_name, f.inv_warehouse_sk
LIMIT 100
