SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand
FROM tpcds.inventory i
JOIN tpcds.warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_country = 'United States'
  AND w.w_street_number = '305'
GROUP BY w.w_warehouse_id, w.w_warehouse_name
