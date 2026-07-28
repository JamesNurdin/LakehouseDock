SELECT
    w.w_warehouse_id,
    w.w_city,
    SUM(i.inv_quantity_on_hand) AS total_qty
FROM tpcds.inventory i
JOIN tpcds.warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_county = 'Fairfield County'
  AND w.w_street_type = 'Ave'
GROUP BY w.w_warehouse_id, w.w_city
ORDER BY total_qty DESC
LIMIT 10
