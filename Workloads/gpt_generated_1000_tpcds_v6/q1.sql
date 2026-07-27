SELECT i.inv_item_sk,
       i.inv_quantity_on_hand,
       w.w_warehouse_name,
       w.w_city,
       w.w_zip
FROM   inventory i
JOIN   warehouse w
     ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE  i.inv_warehouse_sk = 10
  AND  w.w_zip = '59275'
ORDER BY i.inv_quantity_on_hand DESC
LIMIT 100
