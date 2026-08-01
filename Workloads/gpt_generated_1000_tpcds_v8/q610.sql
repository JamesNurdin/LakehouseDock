WITH sampled_inventory AS (
  SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
  FROM inventory TABLESAMPLE BERNOULLI (10)
),
category_intersection AS (
  SELECT i_category FROM item WHERE i_class = 'swimwear'
  INTERSECT
  SELECT i_category FROM item WHERE i_brand = 'Brand1'
)

SELECT
  i.i_category,
  SUM(si.inv_quantity_on_hand) AS total_qty,
  COUNT(DISTINCT i.i_item_sk) AS distinct_items,
  MAX(i.i_current_price) AS price_metric
FROM sampled_inventory si
JOIN item i
  ON si.inv_item_sk = i.i_item_sk
WHERE i.i_rec_start_date <= DATE '2000-01-01'
  AND i.i_category IN (SELECT i_category FROM category_intersection)
  AND EXISTS (
    SELECT 1 FROM inventory inv2
    WHERE inv2.inv_warehouse_sk = si.inv_warehouse_sk
      AND inv2.inv_quantity_on_hand > si.inv_quantity_on_hand
  )
GROUP BY i.i_category
HAVING SUM(si.inv_quantity_on_hand) > 1000

UNION ALL

SELECT
  i2.i_category,
  SUM(si2.inv_quantity_on_hand) AS total_qty,
  COUNT(DISTINCT i2.i_item_sk) AS distinct_items,
  MIN(i2.i_current_price) AS price_metric
FROM sampled_inventory si2
JOIN item i2
  ON si2.inv_item_sk = i2.i_item_sk
WHERE i2.i_rec_end_date >= DATE '2000-01-01'
  AND i2.i_category IN (SELECT i_category FROM category_intersection)
  AND EXISTS (
    SELECT 1 FROM inventory inv3
    WHERE inv3.inv_warehouse_sk = si2.inv_warehouse_sk
      AND inv3.inv_quantity_on_hand < si2.inv_quantity_on_hand
  )
GROUP BY i2.i_category
HAVING COUNT(DISTINCT i2.i_item_sk) >= 5

ORDER BY total_qty DESC, i_category
OFFSET 10 ROWS FETCH FIRST 100 ROWS ONLY
