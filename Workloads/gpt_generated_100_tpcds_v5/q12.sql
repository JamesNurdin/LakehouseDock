WITH avg_qty AS (
    SELECT avg(inv_quantity_on_hand) AS avg_qty
    FROM inventory
)
SELECT
    i.i_color AS color,
    i.i_brand AS brand,
    SUM(inv.inv_quantity_on_hand) AS total_quantity,
    COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
FROM inventory inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
WHERE inv.inv_quantity_on_hand > (SELECT avg_qty FROM avg_qty)
  AND i.i_color IN ('sandy', 'olive')
GROUP BY i.i_color, i.i_brand

UNION ALL

SELECT
    i.i_color AS color,
    i.i_brand AS brand,
    SUM(inv.inv_quantity_on_hand) AS total_quantity,
    COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
FROM inventory inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
WHERE i.i_class_id = 9
  AND inv.inv_quantity_on_hand BETWEEN 200 AND 800
  AND EXISTS (
      SELECT 1
      FROM item i2
      WHERE i2.i_brand_id = i.i_brand_id
        AND i2.i_color = 'pale'
  )
GROUP BY i.i_color, i.i_brand

ORDER BY total_quantity DESC
LIMIT 100
