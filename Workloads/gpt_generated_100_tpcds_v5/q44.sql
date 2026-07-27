SELECT DISTINCT
    w.w_city,
    w.w_state,
    i.inv_item_sk
FROM tpcds.inventory i
JOIN tpcds.warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.inv_warehouse_sk IN (3, 9)
  AND i.inv_date_sk = 2451053
ORDER BY w.w_city, w.w_state
LIMIT 100
