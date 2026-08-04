SELECT
    w.w_warehouse_id,
    w.w_city,
    SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand
FROM tpcds.inventory AS i
JOIN tpcds.warehouse AS w
    ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.inv_warehouse_sk = 13
  AND i.inv_quantity_on_hand > 500
  AND w.w_street_type = 'Ave'
GROUP BY w.w_warehouse_id, w.w_city
ORDER BY total_quantity_on_hand DESC
