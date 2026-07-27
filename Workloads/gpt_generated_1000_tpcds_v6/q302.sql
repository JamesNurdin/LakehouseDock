SELECT DISTINCT i.i_brand, i.i_category, inv.inv_quantity_on_hand
FROM tpcds.inventory AS inv
JOIN tpcds.item AS i
  ON inv.inv_item_sk = i.i_item_sk
WHERE inv.inv_warehouse_sk = 18
  AND i.i_formulation LIKE '%seashell%'
LIMIT 100
