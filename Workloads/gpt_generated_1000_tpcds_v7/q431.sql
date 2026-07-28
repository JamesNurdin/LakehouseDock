SELECT 
    w.w_city,
    w.w_zip,
    SUM(i.inv_quantity_on_hand) AS total_qty
FROM tpcds.inventory i
JOIN tpcds.warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.inv_item_sk = 101425
  AND i.inv_date_sk = 2450955
GROUP BY w.w_city, w.w_zip
LIMIT 100
