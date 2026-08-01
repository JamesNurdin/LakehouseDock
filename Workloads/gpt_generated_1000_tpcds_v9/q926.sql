SELECT
  w.w_warehouse_id,
  w.w_warehouse_name,
  w.w_city,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(cr.cr_fee) AS avg_return_fee,
  SUM(cr.cr_return_quantity) AS total_return_quantity,
  COUNT(*) AS returns_count,
  MIN(cr.cr_return_amount) AS min_return_amount,
  MAX(cr.cr_return_amount) AS max_return_amount
FROM tpcds.catalog_returns cr
JOIN tpcds.warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE cr.cr_return_amount > 100.00
  AND cr.cr_fee >= 20.00
  AND cr.cr_refunded_cash > 500.00
  AND cr.cr_call_center_sk IN (19, 34)
  AND cr.cr_returned_date_sk BETWEEN 2450800 AND 2451100
  AND w.w_city IN ('Pleasant Valley', 'Greenwood')
  AND EXISTS (
    SELECT 1
    FROM tpcds.inventory i
    WHERE i.inv_warehouse_sk = w.w_warehouse_sk
      AND i.inv_item_sk = cr.cr_item_sk
      AND i.inv_quantity_on_hand > 0
      AND i.inv_date_sk = cr.cr_returned_date_sk
  )
GROUP BY w.w_warehouse_id, w.w_warehouse_name, w.w_city
ORDER BY total_return_amount DESC
LIMIT 100
