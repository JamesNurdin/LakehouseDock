WITH brand_inventory AS (
  SELECT
    it.i_brand,
    it.i_category,
    i.inv_warehouse_sk,
    SUM(i.inv_quantity_on_hand) AS total_quantity,
    AVG(it.i_wholesale_cost) AS avg_wholesale_cost,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items
  FROM inventory i
  JOIN item it
    ON i.inv_item_sk = it.i_item_sk
  WHERE i.inv_quantity_on_hand > 200
    AND it.i_wholesale_cost BETWEEN 0.5 AND 10.0
    AND it.i_brand_id IN (5003002, 1001001, 3002001)
  GROUP BY it.i_brand, it.i_category, i.inv_warehouse_sk
)
SELECT
  i_brand AS brand,
  i_category AS category,
  inv_warehouse_sk,
  total_quantity,
  avg_wholesale_cost,
  distinct_items,
  RANK() OVER (ORDER BY total_quantity DESC) AS quantity_rank
FROM brand_inventory
WHERE total_quantity > 500
ORDER BY quantity_rank
LIMIT 50
