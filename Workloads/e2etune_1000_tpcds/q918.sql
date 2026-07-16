WITH warehouse_inventory AS (
  SELECT
    w.w_warehouse_name,
    w.w_state,
    w.w_gmt_offset,
    SUM(inv.inv_quantity_on_hand) AS total_quantity,
    SUM(inv.inv_quantity_on_hand * i.i_current_price) AS total_inventory_value,
    AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items
  FROM inventory inv
  JOIN item i ON inv.inv_item_sk = i.i_item_sk
  JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE inv.inv_date_sk BETWEEN 20230101 AND 20231231
    AND i.i_category = 'Electronics'
    AND i.i_brand IN ('BrandA', 'BrandB')
  GROUP BY w.w_warehouse_name, w.w_state, w.w_gmt_offset
  HAVING SUM(inv.inv_quantity_on_hand) > 1000
)
SELECT
  w_warehouse_name,
  w_state,
  w_gmt_offset,
  total_quantity,
  total_inventory_value,
  avg_wholesale_cost,
  distinct_items,
  total_inventory_value / NULLIF(total_quantity, 0) AS avg_price_per_unit,
  CASE
    WHEN total_quantity >= 5000 THEN 'Large'
    WHEN total_quantity >= 2000 THEN 'Medium'
    ELSE 'Small'
  END AS size_category,
  RANK() OVER (ORDER BY total_inventory_value DESC) AS revenue_rank
FROM warehouse_inventory
ORDER BY revenue_rank
LIMIT 10
